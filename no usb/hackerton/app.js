const BASE_URL = '/api';
const FAV_STORAGE_KEY = 'flood_risk_favorites';

const appState = {
    currentLat: 37.4842,
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 100',
    currentRainfall: 50,
    currentLevel: '안전',
    currentBuildingId: null,
    currentScoreId: null,
    cachedScoreData: null,
    mapInstance: null,
    mapMarker: null,
    mapCircle: null,
    shelterMarkers: [],
    gridLayers: [],
    gridRequestId: 0
};

async function safeParseJson(response) {
    const text = await response.text();
    try {
        return { json: JSON.parse(text), backendUnreachable: false };
    } catch (e) {
        console.error('JSON Parsing Failed:', text.slice(0, 200));
        return { json: null, backendUnreachable: true };
    }
}

function showCustomModal(title, message) {
    document.getElementById('modal-title').innerText = title;
    document.getElementById('modal-msg').innerText = message;
    document.getElementById('custom-modal').style.display = 'flex';
}

function hideCustomModal() {
    document.getElementById('custom-modal').style.display = 'none';
}

function updateMapLayers(lat, lng, level, popupText) {
    if (!appState.mapInstance) return;
    const targetPos = [lat, lng];

    if (appState.mapMarker) {
        appState.mapMarker.setLatLng(targetPos);
        if (popupText) {
            appState.mapMarker.bindPopup(popupText);
            setTimeout(() => {
                if (appState.mapMarker && appState.mapInstance) {
                    appState.mapMarker.openPopup();
                }
            }, 100);
        }
    }
    if (appState.mapCircle) {
        appState.mapCircle.setLatLng(targetPos);
        const col = getRiskColor(level);
        appState.mapCircle.setStyle({ color: col, fillColor: col });
    }
}

function initRealMap() {
    if (appState.mapInstance) {
        appState.mapInstance.remove();
    }

    appState.mapInstance = L.map('map-canvas', { zoomControl: false }).setView([appState.currentLat, appState.currentLng], 15);

    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap'
    }).addTo(appState.mapInstance);

    const targetColor = getRiskColor('안전');

    appState.mapCircle = L.circle([appState.currentLat, appState.currentLng], {
        color: targetColor, fillColor: targetColor, fillOpacity: 0.2, radius: 150
    }).addTo(appState.mapInstance);

    appState.mapMarker = L.marker([appState.currentLat, appState.currentLng]).addTo(appState.mapInstance)
        .bindPopup(appState.currentAddress).openPopup();

    document.getElementById('sheet-title-addr').innerText = appState.currentAddress;

    appState.mapInstance.on('moveend', () => {
        renderRiskGrid();
    });

    renderRiskGrid();
    updateFavToggleUI();
}

function toggleBottomSheet() {
    const sheet = document.getElementById('main-bottom-sheet');
    if (sheet) {
        sheet.classList.toggle('collapsed');
    }
}

function resetLocationBoundState() {
    appState.currentBuildingId = null;
    appState.currentScoreId = null;
    appState.cachedScoreData = null;
}

function tryGeoLocate() {
    if (!('geolocation' in navigator)) {
        showCustomModal('위치 확인 불가', 'GPS를 지원하지 않는 환경입니다. 주소를 직접 검색해 주세요.');
        return;
    }

    navigator.geolocation.getCurrentPosition(
        (pos) => {
            appState.currentLat = pos.coords.latitude;
            appState.currentLng = pos.coords.longitude;
            appState.currentAddress = '현재 위치';
            resetLocationBoundState();
            initRealMap();
        },
        () => {
            showCustomModal('위치 확인 불가', 'GPS 권한이 없거나 탐색을 완료하지 못했습니다. 시범 구역 주소를 검색해 주세요.');
        },
        { timeout: 5000 }
    );
}

async function handleSearch() {
    const inputEl = document.getElementById('map-search-input');
    if (!inputEl || !inputEl.value.trim()) {
        showCustomModal('알림', '검색할 도로명 또는 지번 주소를 입력해 주세요.');
        return;
    }

    const keyword = inputEl.value.trim();

    try {
        const response = await fetch(`${BASE_URL}/geocode?address=${encodeURIComponent(keyword)}`);
        const { json: resJson, backendUnreachable } = await safeParseJson(response);

        if (backendUnreachable) {
            showCustomModal('백엔드 연결 실패', '통신 장애가 발생했거나 서버 가동이 중단된 상태입니다.');
            return;
        }

        if (response.status === 404 || !response.ok || resJson.success === false) {
            showCustomModal('검색 결과 없음', resJson.error?.message || '입력하신 주소 정보를 조회할 수 없습니다.');
            return;
        }

        const geo = resJson.data;
        appState.currentLat = geo.lat;
        appState.currentLng = geo.lng;
        appState.currentAddress = geo.address_road || geo.address_jibun || keyword;
        resetLocationBoundState();

        document.getElementById('sheet-title-addr').innerText = appState.currentAddress;
        updateFavToggleUI();

        if (appState.mapInstance) {
            appState.mapInstance.setView([appState.currentLat, appState.currentLng], 16);
            updateMapLayers(appState.currentLat, appState.currentLng, '안전', appState.currentAddress);
        }

        renderRiskGrid();
        await loadReportApi();
        showCustomModal('위치 갱신', `'${appState.currentAddress}' 지점의 리포트가 업데이트되었습니다.`);
    } catch (error) {
        console.error(error);
        showCustomModal('서버 오류', '주소 변환 및 위험성 전처리 데이터 바인딩에 실패했습니다.');
    }
}

async function fetchRiskScore(rainfallScenario) {
    let body = {};
    if (appState.currentBuildingId) {
        body = { building_id: appState.currentBuildingId, rainfall_scenario: rainfallScenario };
    } else {
        body = { lat: appState.currentLat, lng: appState.currentLng, rainfall_scenario: rainfallScenario };
    }

    try {
        const response = await fetch(`${BASE_URL}/risk-score`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (response.status === 422) return { ok: false, notCovered: true };
        if (response.status === 503) return { ok: false, llmFailed: true };
        if (!response.ok) return { ok: false };

        const { json: resJson, backendUnreachable } = await safeParseJson(response);
        if (backendUnreachable || !resJson || resJson.success === false) return { ok: false };

        const data = resJson.data;
        appState.currentBuildingId = data.building?.building_id || null;
        appState.currentScoreId = data.score_id ?? null;
        appState.currentLevel = data.risk_level;
        
        if (rainfallScenario === 50) {
            appState.cachedScoreData = data;
        }
        return { ok: true, data };
    } catch (error) {
        console.error('risk-score 호출 실패:', error);
        return { ok: false };
    }
}

async function loadReportApi() {
    const errorCard = document.getElementById('error-no-data');
    const mainContent = document.getElementById('report-main-content');
    document.getElementById('api-report-addr').innerText = appState.currentAddress;

    errorCard.style.display = 'none';
    mainContent.style.display = 'block';

    const result = await fetchRiskScore(50);
    if (!result.ok) {
        errorCard.style.display = 'block';
        mainContent.style.display = 'none';
        if (result.llmFailed) showCustomModal('AI 분석 실패', '종합 위험성 지표 산출 모델 연동에 실패했습니다.');
        if (result.notCovered) showCustomModal('분석 불가 구역', '해당 구역은 분석 대상 시범 운영 가구 구역이 아닙니다.');
        return;
    }

    const data = result.data;
    updateMapLayers(appState.currentLat, appState.currentLng, data.risk_level, appState.currentAddress);
    await loadWeatherBanner();

    setTextWithPulse(document.getElementById('api-report-score'), data.total_score);
    const gradeEl = document.getElementById('api-report-grade');
    gradeEl.innerText = data.risk_level;
    gradeEl.style.color = getRiskColor(data.risk_level);

    const gaugeBar = document.getElementById('api-gauge-bar');
    if (gaugeBar) {
        const angle = -45 + (data.total_score * 1.8);
        gaugeBar.style.borderColor = getRiskColor(data.risk_level);
        gaugeBar.style.transform = `rotate(${angle}deg)`;
    }

    updatePhaseBarHighlight(data.risk_level);
    document.getElementById('api-report-summary').innerText = data.summary ? `"${data.summary}"` : "분석 완료";
    document.getElementById('api-llm-full-paragraph').innerText = data.summary || "선택된 위치의 침수 요인 분석 결과가 정상 매핑되었습니다.";
    
    renderFourFactors(data.factors || []);
    loadShelters(data.risk_level);
}

function updatePhaseBarHighlight(currentLevel) {
    document.querySelectorAll('.phase-chunk').forEach(chunk => chunk.classList.remove('active'));
    let targetClass = null;
    if (currentLevel === '안전') targetClass = '.chunk-safe';
    else if (currentLevel === '주의') targetClass = '.chunk-watch';
    else if (currentLevel === '경고') targetClass = '.chunk-warn';
    else if (currentLevel === '위험') targetClass = '.chunk-danger';

    if (targetClass) {
        const targetChunk = document.querySelector(targetClass);
        if (targetChunk) targetChunk.classList.add('active');
    }
}

function renderFourFactors(factors) {
    const listContainer = document.getElementById('api-factor-list');
    if (!listContainer || !factors) return;

    listContainer.innerHTML = factors.map(f => {
        const contribution = f.contribution ?? 0;
        return `
            <div class="factor-card">
                <div class="factor-header">
                    <span class="factor-title">점수 요인: ${f.factor_type}</span>
                    <span class="factor-meta">기여도 <span class="factor-percent-highlight">${contribution}%</span></span>
                </div>
                <div class="factor-bar-bg">
                    <div class="factor-bar-fill" style="width: ${contribution}%; background: ${getRiskColor(appState.currentLevel)};"></div>
                </div>
                <div class="factor-desc"><strong>AI 설명:</strong> ${f.description}</div>
            </div>
        `;
    }).join('');
}

function retryLLMGeneration() {
    loadReportApi();
}

async function loadResponseGuideApi() {
    document.getElementById('api-guide-addr').innerText = appState.currentAddress;
    let d = null;

    if (appState.currentRainfall === 50 && appState.cachedScoreData) {
        d = appState.cachedScoreData;
    } else {
        const scoreResult = await fetchRiskScore(appState.currentRainfall);
        if (!scoreResult.ok) return;
        d = scoreResult.data;
    }

    setTextWithPulse(document.getElementById('api-recalc-score'), d.total_score);
    const recalcGrade = document.getElementById('api-recalc-grade');
    recalcGrade.innerText = d.risk_level;
    recalcGrade.style.color = getRiskColor(d.risk_level);

    if (!appState.currentScoreId) return;

    try {
        const response = await fetch(`${BASE_URL}/response-guide`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ score_id: appState.currentScoreId })
        });

        if (!response.ok) return;
        const { json: resJson } = await safeParseJson(response);
        if (!resJson || resJson.success === false) return;
        const data = resJson.data;

        const chip = document.getElementById('tier-chip');
        if (chip) {
            chip.innerText = `${data.risk_level} 단계 행동 요령`;
            chip.style.color = '#fff';
            chip.style.background = getRiskColor(data.risk_level);
        }

        const deltaBadge = document.getElementById('delta-badge');
        const rainGap = appState.currentRainfall - 50;
        if (rainGap !== 0) {
            deltaBadge.innerText = rainGap > 0 ? `기준 대비 +${rainGap}mm` : `기준 대비 ${rainGap}mm`;
            deltaBadge.style.display = 'inline-block';
        } else {
            deltaBadge.style.display = 'none';
        }

        renderChecklist('api-guide-list-prep', data.guides || []);

        const evacBox = document.getElementById('evac-guide-box');
        const isHighRisk = d.risk_level === '경고' || d.risk_level === '위험';
        if (isHighRisk) {
            const evacGuides = (data.guides || []).filter(g => g.includes('대피') || g.includes('이동'));
            renderChecklist('api-guide-list-evac', evacGuides.length ? evacGuides : ["위험 수위 도달 시 즉시 지정 대피소로 대피하십시오."]);
            evacBox.style.display = 'block';
        } else {
            evacBox.style.display = 'none';
        }
    } catch (error) {
        console.error(error);
    }
}

function renderChecklist(elementId, items) {
    const container = document.getElementById(elementId);
    if (!container) return;
    container.innerHTML = items.map((item, idx) => `
        <div class="chk-row">
            <input type="checkbox" id="${elementId}-${idx}" class="custom-chk">
            <label for="${elementId}-${idx}">${item}</label>
        </div>
    `).join('');
}

let rainDebounceTimer = null;
function handleRainSlider(slider) {
    appState.currentRainfall = parseInt(slider.value);
    document.getElementById('rain-val').innerText = slider.value;
    clearTimeout(rainDebounceTimer);
    rainDebounceTimer = setTimeout(loadResponseGuideApi, 300);
}

function retryResponseGuide() {
    loadResponseGuideApi();
}

async function loadWeatherBanner() {
    try {
        const params = new URLSearchParams({ lat: appState.currentLat, lng: appState.currentLng });
        const response = await fetch(`${BASE_URL}/rainfall?${params.toString()}`);
        const banner = document.getElementById('weather-alert-banner');
        if (!banner) return;

        if (!response.ok) { banner.style.display = 'none'; return; }
        const resJson = await response.json();
        if (resJson.success && resJson.data?.warning_level) {
            banner.innerText = `기상 특보: ${resJson.data.warning_level} 발령 중 (${resJson.data.current_rainfall_mm}mm/h)`;
            banner.style.display = 'block';
        } else {
            banner.style.display = 'none';
        }
    } catch (e) {
        console.error(e);
    }
}

async function loadShelters(level) {
    if (level !== '경고' && level !== '위험') {
        renderShelters([]);
        return;
    }
    try {
        const params = new URLSearchParams({ lat: appState.currentLat, lng: appState.currentLng });
        const response = await fetch(`${BASE_URL}/shelters?${params.toString()}`);
        if (!response.ok) { renderShelters([]); return; }
        const resJson = await response.json();
        renderShelters(resJson.success ? (resJson.data?.shelters || []) : []);
    } catch (error) {
        console.error(error);
        renderShelters([]);
    }
}

function renderShelters(shelters) {
    if (!appState.mapInstance) return;
    appState.shelterMarkers.forEach(m => appState.mapInstance.removeLayer(m));
    appState.shelterMarkers = [];

    const emptyMsg = document.getElementById('shelter-empty-msg');
    const listContainer = document.getElementById('shelter-list');

    if (shelters.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        if (listContainer) listContainer.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';

    shelters.forEach(s => {
        const marker = L.marker([s.lat, s.lng], {
            icon: L.divIcon({
                className: 'custom-shelter-icon',
                html: `<div style="background:#16a34a; color:white; padding:4px 8px; border-radius:8px; font-size:10px; font-weight:bold; border:1px solid white; box-shadow:0 2px 6px rgba(0,0,0,0.2);">🏡 대피소</div>`,
                iconAnchor: [30, 10]
            })
        }).addTo(appState.mapInstance).bindPopup(`<b>${s.shelter_name}</b><br>${s.address}`);
        appState.shelterMarkers.push(marker);
    });

    if (listContainer) {
        listContainer.innerHTML = shelters.map(s => `
            <div class="shelter-card">
                <div class="shelter-name">🏡 ${s.shelter_name} (약 ${s.distance_m}m)</div>
                <div class="shelter-addr">${s.address} (수용 인원: ${s.capacity}명)</div>
            </div>
        `).join('');
    }
}

async function renderRiskGrid() {
    if (!appState.mapInstance) return;
    const bounds = appState.mapInstance.getBounds();
    const requestId = ++appState.gridRequestId;

    try {
        const params = new URLSearchParams({
            min_lat: bounds.getSouthWest().lat,
            min_lng: bounds.getSouthWest().lng,
            max_lat: bounds.getNorthEast().lat,
            max_lng: bounds.getNorthEast().lng
        });

        const response = await fetch(`${BASE_URL}/risk-map?${params.toString()}`);
        if (requestId !== appState.gridRequestId || !response.ok) return;

        const resJson = await response.json();
        if (!resJson || resJson.success === false) return;

        appState.gridLayers.forEach(layer => appState.mapInstance.removeLayer(layer));
        appState.gridLayers = [];

        const cells = resJson.data?.cells || [];
        const cellSize = 0.001;

        cells.forEach(cell => {
            const col = getRiskColor(cell.risk_level);
            const rect = L.rectangle([
                [cell.lat - cellSize / 2, cell.lng - cellSize / 2],
                [cell.lat + cellSize / 2, cell.lng + cellSize / 2]
            ], {
                color: col, weight: 1, fillColor: col, fillOpacity: 0.15, interactive: false
            }).addTo(appState.mapInstance);
            appState.gridLayers.push(rect);
        });
    } catch (error) {
        console.error(error);
    }
}

async function loadHistoryApi() {
    try {
        const response = await fetch(`${BASE_URL}/history?limit=20`);
        const { json: resJson } = await safeParseJson(response);
        if (response.ok && resJson && resJson.success) {
            renderHistoryList(resJson.data?.history || []);
        } else {
            renderHistoryList([]);
        }
    } catch (e) {
        console.error(e);
        renderHistoryList([]);
    }
}

function renderHistoryList(history) {
    const listContainer = document.getElementById('history-list');
    const emptyMsg = document.getElementById('history-empty-msg');
    if (!listContainer) return;

    if (history.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        listContainer.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';
    listContainer.innerHTML = history.map(h => {
        const dateText = h.created_at ? new Date(h.created_at).toLocaleString('ko-KR') : '';
        return `
            <div class="history-item-row">
                <div class="history-item-main">
                    <span class="history-addr">${h.address_road || '알 수 없는 건물'}</span>
                    <span class="history-level-badge" style="background:${getRiskColor(h.risk_level)}">${h.risk_level}</span>
                </div>
                <div class="history-meta">침수 위험 지표: ${h.total_score}점 · 조건 시나리오: ${h.rainfall_scenario}mm/h · ${dateText}</div>
            </div>
        `;
    }).join('');
}

function setSheetTab(tabId) {
    document.querySelectorAll('.sheet-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.sheet-pane').forEach(p => p.classList.remove('active'));

    const tabEl = document.getElementById(`tab-${tabId}`);
    const paneEl = document.getElementById(`pane-${tabId}`);
    if (tabEl) tabEl.classList.add('active');
    if (paneEl) paneEl.classList.add('active');

    if (tabId === 'fav') renderFavoritesList();
    if (tabId === 'history') loadHistoryApi();
}

function goToShelterTab() {
    switchView('view1');
    setSheetTab('shelter');
}

function toggleFavorite() {
    const addr = appState.currentAddress;
    if (addr === '위치 선택 대기 중' || addr === '현재 위치') {
        showCustomModal('저장 불가', '관심 주소 필터링이 완료되지 않았습니다.');
        return;
    }

    let favs = getFavoritesFromStorage();
    const idx = favs.findIndex(f => f.address === addr);

    if (idx > -1) {
        favs.splice(idx, 1);
        showCustomModal('관심 위치 해제', '관심 모니터링 구역에서 삭제되었습니다.');
    } else {
        favs.push({ address: addr, lat: appState.currentLat, lng: appState.currentLng });
        showCustomModal('관심 위치 등록', '상시 모니터링 관심 구역에 추가되었습니다.');
    }

    localStorage.setItem(FAV_STORAGE_KEY, JSON.stringify(favs));
    updateFavToggleUI();
}

function getFavoritesFromStorage() {
    const raw = localStorage.getItem(FAV_STORAGE_KEY);
    if (!raw) return [];
    try { return JSON.parse(raw); } catch (e) { return []; }
}

function updateFavToggleUI() {
    const btn = document.getElementById('btn-fav-toggle');
    if (!btn) return;
    const favs = getFavoritesFromStorage();
    const exists = favs.some(f => f.address === appState.currentAddress);
    if (exists) {
        btn.innerText = '★ 관심 위치 취소';
        btn.classList.add('saved');
    } else {
        btn.innerText = '☆ 관심 위치 저장';
        btn.classList.remove('saved');
    }
}

function renderFavoritesList() {
    const listContainer = document.getElementById('fav-list');
    const emptyMsg = document.getElementById('fav-empty-msg');
    if (!listContainer) return;

    const favs = getFavoritesFromStorage();
    if (favs.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        listContainer.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';
    listContainer.innerHTML = favs.map((f, idx) => `
        <div class="fav-item-row">
            <span class="fav-item-text">${f.address}</span>
            <div class="fav-item-actions">
                <button class="btn-fav-goto" onclick="handleGoToFav(${idx})">이동</button>
                <button class="btn-fav-remove" onclick="handleRemoveFav(${idx})">삭제</button>
            </div>
        </div>
    `).join('');
}

function handleGoToFav(idx) {
    const favs = getFavoritesFromStorage();
    const f = favs[idx];
    if (!f) return;

    appState.currentLat = f.lat;
    appState.currentLng = f.lng;
    appState.currentAddress = f.address;
    resetLocationBoundState();

    document.getElementById('sheet-title-addr').innerText = f.address;
    document.getElementById('map-search-input').value = f.address;

    if (appState.mapInstance) {
        appState.mapInstance.setView([f.lat, f.lng], 16);
        updateMapLayers(f.lat, f.lng, '주의', f.address);
    }

    renderRiskGrid();
    updateFavToggleUI();
    setSheetTab('info');
}

function handleRemoveFav(idx) {
    let favs = getFavoritesFromStorage();
    favs.splice(idx, 1);
    localStorage.setItem(FAV_STORAGE_KEY, JSON.stringify(favs));
    updateFavToggleUI();
    renderFavoritesList();
}

function setTextWithPulse(el, newValue) {
    if (!el) return;
    const changed = el.innerText !== String(newValue);
    el.innerText = newValue;
    if (changed) {
        el.classList.remove('score-pulse');
        void el.offsetWidth;
        el.classList.add('score-pulse');
    }
}

function getRiskColor(level) {
    if (level === '안전') return '#10b981';
    if (level === '주의') return '#f59e0b';
    if (level === '경고') return '#f97316';
    if (level === '위험') return '#ef4444';
    return '#94a3b8';
}

function switchView(viewId) {
    document.querySelectorAll('.view-container').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.act-btn').forEach(b => b.classList.remove('active'));

    const viewEl = document.getElementById(viewId);
    if (viewEl) viewEl.classList.add('active');
    
    const btnEl = document.getElementById(`nav-btn-${viewId}`);
    if (btnEl) btnEl.classList.add('active');

    if (viewId === 'view2' && !appState.cachedScoreData) loadReportApi();
    if (viewId === 'view3') loadResponseGuideApi();
}

window.addEventListener('DOMContentLoaded', () => {
    initRealMap();
    tryGeoLocate();
});