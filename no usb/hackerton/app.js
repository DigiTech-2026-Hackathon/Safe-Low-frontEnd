// 백엔드 주소 (Vercel 프록시 rewrites 설정을 활용하기 위해 상대경로로 변경)
const BASE_URL = '/api';

const FAV_STORAGE_KEY = 'flood_risk_favorites';

const appState = {
    currentLat: 37.4842,
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 100',
    currentRainfall: 50,
    currentLevel: '안전',       // 실시간 위험 단계 저장용
    currentBuildingId: null,   // risk-score find-or-create 결과 재사용 (재계산 시 lat/lng 대신 사용)
    lastFactors: [],           // 최근 risk-score 요인분해 결과 (response-guide 컨텍스트로 재사용)
    mapInstance: null,
    mapMarker: null,
    mapCircle: null,
    shelterMarkers: [],
    gridLayers: [],
    isLlmFailedMode: false
};

// 알림 모달 제어
function showCustomModal(title, message) {
    document.getElementById('modal-title').innerText = title;
    document.getElementById('modal-msg').innerText = message;
    document.getElementById('custom-modal').style.display = 'flex';
}

function hideCustomModal() {
    document.getElementById('custom-modal').style.display = 'none';
}

/**
 * 지도 레이어 및 원형 반경 동기화 통합 함수
 */
function updateMapLayers(lat, lng, level, popupText) {
    if (!appState.mapInstance) return;
    const targetPos = [lat, lng];

    if (appState.mapMarker) {
        appState.mapMarker.setLatLng(targetPos).bindPopup(popupText).openPopup();
    }
    if (appState.mapCircle) {
        appState.mapCircle.setLatLng(targetPos);
        const col = getRiskColor(level);
        appState.mapCircle.setStyle({ color: col, fillColor: col });
    }
}

// 초기 지도 인스턴스 설정
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

    renderRiskGrid();
    updateFavToggleUI();
}

function toggleBottomSheet() {
    const sheet = document.getElementById('main-bottom-sheet');
    if (sheet) {
        sheet.classList.toggle('collapsed');
        syncGeolocationButtonPosition();
    }
}

function syncGeolocationButtonPosition() {
    const geoBtn = document.getElementById('geo-btn');
    if (geoBtn) {
        geoBtn.style.bottom = '';
    }
}

// 위치가 바뀔 때마다 이전 위치의 building_id/요인 캐시를 초기화
function resetLocationBoundState() {
    appState.currentBuildingId = null;
    appState.lastFactors = [];
    appState.isLlmFailedMode = false;
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
            showCustomModal('위치 확인 불가', 'GPS 권한이 없어 기본 위치로 표시합니다. 상단 검색창에서 주소를 입력해 주세요.');
        },
        { timeout: 5000 }
    );
}

/**
 * [연동] GET /api/geocode 호출
 * 백엔드 스펙 반영: ?address=<주소문자열>
 */
async function handleSearch() {
    const inputEl = document.getElementById('map-search-input');
    if (!inputEl || !inputEl.value.trim()) {
        showCustomModal('알림', '검색할 주소 또는 건물명을 입력해 주세요.');
        return;
    }

    const keyword = inputEl.value.trim();

    try {
        // 백엔드 API 계약에 맞춰 쿼리 파라미터를 address로 수정
        const response = await fetch(`${BASE_URL}/geocode?address=${encodeURIComponent(keyword)}`);
        const resJson = await response.json();

        // 백엔드 공통 에러 포맷 처리 ({ success: false, error: { message } })
        if (!response.ok || resJson.success === false) {
            showCustomModal('검색 결과 없음', resJson.error?.message || '해당 주소/건물명을 찾을 수 없습니다.');
            return;
        }

        const geo = resJson.data;

        if (geo.is_valid === false) {
            showCustomModal('분석 불가 지역', '해당 구역은 침수 분석 정보가 수집되지 않는 구역입니다.');
            return;
        }

        // 백엔드 응답 데이터 구조에 맞게 할당
        appState.currentLat = geo.lat;
        appState.currentLng = geo.lng;
        appState.currentAddress = geo.address || keyword;
        resetLocationBoundState();

        document.getElementById('sheet-title-addr').innerText = appState.currentAddress;
        updateFavToggleUI();

        if (appState.mapInstance) {
            appState.mapInstance.setView([appState.currentLat, appState.currentLng], 16);
            updateMapLayers(appState.currentLat, appState.currentLng, '안전', appState.currentAddress);
        }

        renderRiskGrid();
        showCustomModal('위치 매핑 완료', `'${appState.currentAddress}'로 이동되었습니다. 아래에서 리포트를 확인하세요.`);
        
        // 검색 성공 후 자동으로 리포트 및 가이드 갱신 유도
        if (document.getElementById('pane-info').classList.contains('active')) {
            loadReportApi();
        }
    } catch (error) {
        console.error(error);
        showCustomModal('서버 오류', '위치 지오코딩 중 서버 오류가 발생했습니다.');
    }
}

/**
 * POST /api/risk-score 공통 호출 헬퍼
 * 백엔드 스펙 반영: rainfall 대신 rainfall_scenario 사용
 */
async function fetchRiskScore(rainfall) {
    // 백엔드 API 계약 본문 { lat, lng, rainfall_scenario } 에 맞춤
    const body = { 
        lat: appState.currentLat, 
        lng: appState.currentLng, 
        rainfall_scenario: rainfall 
    };

    const response = await fetch(`${BASE_URL}/risk-score`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
    });

    const resJson = await response.json();

    if (!response.ok || resJson.success === false) {
        return { ok: false, notCovered: false, error: resJson.error };
    }

    const data = resJson.data;

    // 대피소와 리포트 연동을 위해 데이터 저장
    appState.currentBuildingId = data.building_id || null;
    appState.currentLevel = data.level || '안전';
    appState.lastFactors = data.factors || [];
    appState.isLlmFailedMode = !!data.llm_failed;

    return { ok: true, data };
}

/**
 * [연동] 화면2(위험 리포트) 및 대피소 데이터 로드
 */
async function loadReportApi() {
    const errorCard = document.getElementById('error-no-data');
    const mainContent = document.getElementById('report-main-content');

    document.getElementById('api-report-addr').innerText = appState.currentAddress;

    try {
        const result = await fetchRiskScore(appState.currentRainfall);

        if (!result.ok) {
            errorCard.style.display = 'block';
            mainContent.style.display = 'none';
            return;
        }

        const data = result.data;
        errorCard.style.display = 'none';
        mainContent.style.display = 'block';

        updateMapLayers(appState.currentLat, appState.currentLng, data.level, appState.currentAddress);

        // 상단 날씨 배너 연동
        renderWeatherBanner(data.warning || null);

        const reportScoreEl = document.getElementById('api-report-score');
        setTextWithPulse(reportScoreEl, data.score);

        const gradeEl = document.getElementById('api-report-grade');
        gradeEl.innerText = data.level;
        gradeEl.style.color = getRiskColor(data.level);

        const gaugeBar = document.getElementById('api-gauge-bar');
        if (gaugeBar) {
            const angle = -45 + (data.score * 1.8);
            gaugeBar.style.borderColor = getRiskColor(data.level);
            gaugeBar.style.transform = `rotate(${angle}deg)`;
        }

        updatePhaseBarHighlight(data.level);
        document.getElementById('api-report-summary').innerText = data.summary ? `"${data.summary}"` : "분석 완료";

        // 요인 분해 데이터 리스트 렌더링
        renderFourFactors(data.factors || []);

        const retryBox = document.getElementById('llm-retry-box');
        const paragraphEl = document.getElementById('api-llm-full-paragraph');

        if (data.llm_failed || !data.full_desc) {
            retryBox.style.display = 'block';
            paragraphEl.innerText = "";
        } else {
            retryBox.style.display = 'none';
            paragraphEl.innerText = data.full_desc;
        }

        const recalcScoreEl = document.getElementById('api-recalc-score');
        if (recalcScoreEl) setTextWithPulse(recalcScoreEl, data.score);
        const recalcGrade = document.getElementById('api-recalc-grade');
        if (recalcGrade) {
            recalcGrade.innerText = data.level;
            recalcGrade.style.color = getRiskColor(data.level);
        }

        // 백엔드에서 전달받은 주변 대피소 기능 연동 활성화
        renderShelters(data.level, data.shelters || []);

    } catch (error) {
        console.error(error);
        errorCard.style.display = 'block';
        mainContent.style.display = 'none';
    }
}

function updatePhaseBarHighlight(currentLevel) {
    document.querySelectorAll('.phase-chunk').forEach(chunk => {
        chunk.classList.remove('active');
    });

    let targetClass = '.chunk-safe';
    if (currentLevel === '주의') targetClass = '.chunk-watch';
    else if (currentLevel === '경고') targetClass = '.chunk-warn';
    else if (currentLevel === '위험') targetClass = '.chunk-danger';

    const targetChunk = document.querySelector(targetClass);
    if (targetChunk) {
        targetChunk.classList.add('active');
    }
}

function renderFourFactors(factors) {
    const listContainer = document.getElementById('api-factor-list');
    if (!listContainer || !factors) return;

    listContainer.innerHTML = factors.map(f => {
        return `
            <div class="factor-card">
                <div class="factor-header">
                    <span class="factor-title">점수 요인: ${f.name}</span>
                    <span class="factor-meta">기여도 <span class="factor-percent-highlight">${f.percent}%</span> | 요인 스코어: <strong>${f.score}점</strong></span>
                </div>
                <div class="factor-bar-bg">
                    <div class="factor-bar-fill" style="width: ${f.score}%; background: ${getRiskColor(f.score > 70 ? '위험' : f.score > 40 ? '경고' : '안전')};"></div>
                </div>
                <div class="factor-desc"><strong>AI 설명:</strong> ${f.desc}</div>
            </div>
        `;
    }).join('');
}

function retryLLMGeneration() {
    showCustomModal('AI 재요청', 'AI 설명 생성을 서버에 다시 요청합니다.');
    loadReportApi();
}

/**
 * [연동] 화면3(시나리오 대응) 데이터 로드 — 강우량 변경 시 점수 재계산 + 대응 안내 재생성
 */
async function loadResponseGuideApi() {
    const guideAddrEl = document.getElementById('api-guide-addr');
    if (guideAddrEl) guideAddrEl.innerText = appState.currentAddress;

    try {
        // 1. 강우 시나리오 변경분을 먼저 risk-score에 반영해 상태 최신화
        const scoreResult = await fetchRiskScore(appState.currentRainfall);
        if (scoreResult.ok) {
            const d = scoreResult.data;
            const recalcScoreEl = document.getElementById('api-recalc-score');
            if (recalcScoreEl) setTextWithPulse(recalcScoreEl, d.score);
            const recalcGrade = document.getElementById('api-recalc-grade');
            if (recalcGrade) {
                recalcGrade.innerText = d.level;
                recalcGrade.style.color = getRiskColor(d.level);
            }
        }

        // 2. response-guide 백엔드 API 요청 호출
        const response = await fetch(`${BASE_URL}/response-guide`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                level: appState.currentLevel,
                rainfall: appState.currentRainfall,
                address: appState.currentAddress,
                factors: appState.lastFactors.map(f => ({ factor_type: f.factor_type, score: f.score }))
            })
        });

        const resJson = await response.json();
        if (!response.ok || resJson.success === false) throw new Error('가이드 조회 실패');
        
        const data = resJson.data;

        const chip = document.getElementById('tier-chip');
        if (chip) {
            chip.innerText = `${appState.currentLevel} 단계 행동 요령`;
            chip.style.color = '#fff';
            chip.style.background = getRiskColor(appState.currentLevel);
            chip.style.borderColor = getRiskColor(appState.currentLevel);
        }

        // 기준 대비 가변 편차 배지 처리
        const deltaBadge = document.getElementById('delta-badge');
        if (deltaBadge) {
            if (data.rain_gap && Math.abs(data.rain_gap) > 0) {
                deltaBadge.innerText = data.rain_gap > 0 ? `기준 대비 +${data.rain_gap}mm` : `기준 대비 ${data.rain_gap}mm`;
                deltaBadge.style.display = 'inline-block';
            } else {
                deltaBadge.style.display = 'none';
            }
        }

        renderChecklist('api-guide-list-prep', data.prep_rules || []);

        const evacBox = document.getElementById('evac-guide-box');
        if (evacBox) {
            if (appState.currentLevel === '경고' || appState.currentLevel === '위험') {
                evacBox.style.display = 'block';
                renderChecklist('api-guide-list-evac', data.evac_rules || []);
            } else {
                evacBox.style.display = 'none';
            }
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
    showCustomModal('안내 재생성', '최신 기상 변화 분석 정보를 기반으로 대응 가이드를 다시 생성했습니다.');
    loadResponseGuideApi();
}

function renderWeatherBanner(warningText) {
    const banner = document.getElementById('weather-alert-banner');
    if (!banner) return;
    if (warningText) {
        banner.innerText = `기상 특보: ${warningText} 활성화`;
        banner.style.display = 'block';
    } else {
        banner.style.display = 'none';
    }
}

function renderRiskGrid() {
    if (!appState.mapInstance) return;
    appState.gridLayers.forEach(layer => appState.mapInstance.removeLayer(layer));
    appState.gridLayers = [];

    const centerLat = appState.currentLat;
    const centerLng = appState.currentLng;
    const step = 0.003;

    for (let i = -1; i <= 1; i++) {
        for (let j = -1; j <= 1; j++) {
            const lat1 = centerLat + (i * step) - (step / 2);
            const lng1 = centerLng + (j * step) - (step / 2);
            const lat2 = lat1 + step;
            const lng2 = lng1 + step;

            let gridLevel = '주의';
            if (i + j === 0) gridLevel = '주의';
            else if ((i + j) % 2 === 0) gridLevel = '안전';

            const col = getRiskColor(gridLevel);
            const rect = L.rectangle([[lat1, lng1], [lat2, lng2]], {
                color: col, weight: 1, fillColor: col, fillOpacity: 0.08
            }).addTo(appState.mapInstance);

            appState.gridLayers.push(rect);
        }
    }
}

function renderShelters(currentLevel, shelters) {
    if (!appState.mapInstance) return;
    appState.shelterMarkers.forEach(m => appState.mapInstance.removeLayer(m));
    appState.shelterMarkers = [];

    const emptyMsg = document.getElementById('shelter-empty-msg');
    const listContainer = document.getElementById('shelter-list');

    // 경고나 위험 단계가 아니더라도 백엔드에서 대피소가 오면 유연하게 그리도록 조건 최적화
    if (!shelters || shelters.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        if (listContainer) listContainer.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';

    shelters.forEach(s => {
        const marker = L.marker([s.lat, s.lng], {
            icon: L.divIcon({
                className: 'custom-shelter-icon',
                html: `<div style="background:#16a34a; color:white; padding:4px 8px; border-radius:8px; font-size:10px; font-weight:bold; white-space:nowrap; border:1px solid white; box-shadow:0 2px 6px rgba(0,0,0,0.2);">🏡 대피소</div>`,
                iconAnchor: [30, 10]
            })
        }).addTo(appState.mapInstance).bindPopup(`<b>${s.name}</b><br>${s.address}`);

        appState.shelterMarkers.push(marker);
    });

    if (listContainer) {
        listContainer.innerHTML = shelters.map(s => `
            <div class="shelter-card">
                <div class="shelter-name">🏡 ${s.name}</div>
                <div class="shelter-addr">${s.address}</div>
            </div>
        `).join('');
    }
}

function setSheetTab(tabId) {
    document.querySelectorAll('.sheet-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.sheet-pane').forEach(p => p.classList.remove('active'));

    if (tabId === 'info') {
        document.getElementById('tab-info').classList.add('active');
        document.getElementById('pane-info').classList.add('active');
    } else if (tabId === 'shelter') {
        document.getElementById('tab-shelter').classList.add('active');
        document.getElementById('pane-shelter').classList.add('active');
        loadReportApi();
    } else if (tabId === 'fav') {
        document.getElementById('tab-fav').classList.add('active');
        document.getElementById('pane-fav').classList.add('active');
        renderFavoritesList();
    }
}

function goToShelterTab() {
    switchView('view1');
    setSheetTab('shelter');
}

function toggleFavorite() {
    const addr = appState.currentAddress;
    if (addr === '위치 선택 대기 중' || addr === '현재 위치') {
        showCustomModal('저장 불가', '관심 위치로 등록할 수 없는 임시 주소 상태입니다.');
        return;
    }

    let favs = getFavoritesFromStorage();
    const idx = favs.findIndex(f => f.address === addr);

    if (idx > -1) {
        favs.splice(idx, 1);
        showCustomModal('관심 위치 해제', '해당 위치를 관심 구역에서 해제하였습니다.');
    } else {
        favs.push({
            address: addr,
            lat: appState.currentLat,
            lng: appState.currentLng
        });
        showCustomModal('관심 위치 추가', '해당 주소를 상시 모니터링 관심 구역으로 등록했습니다.');
    }

    localStorage.setItem(FAV_STORAGE_KEY, JSON.stringify(favs));
    updateFavToggleUI();
    renderFavoritesList();
}

function getFavoritesFromStorage() {
    const raw = localStorage.getItem(FAV_STORAGE_KEY);
    if (!raw) return [];
    try { return JSON.parse(raw); } catch (e) { return []; }
}

function updateFavToggleUI() {
    const btn = document.getElementById('btn-fav-toggle');
    if (!btn) return;

    let favs = getFavoritesFromStorage();
    const exists = favs.some(f => f.address === appState.currentAddress);
    btn.innerText = exists ? '★ 관심 위치 취소' : '☆ 관심 위치 저장';
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

    listContainer.innerHTML = favs.map((f, index) => `
        <div class="fav-item-row">
            <span class="fav-item-text">${f.address}</span>
            <div class="fav-item-actions">
                <button class="btn-fav-goto" onclick="handleGoToFav(${index})">이동</button>
                <button class="btn-fav-remove" onclick="handleRemoveFav(${index})">삭제</button>
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
    return '#ef4444';
}

function switchView(viewId) {
    document.querySelectorAll('.view-container').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.act-btn').forEach(b => b.classList.remove('active'));

    document.getElementById(viewId).classList.add('active');
    document.getElementById(`nav-btn-${viewId}`).classList.add('active');

    if (viewId === 'view2') loadReportApi();
    if (viewId === 'view3') loadResponseGuideApi();
}

window.addEventListener('DOMContentLoaded', () => {
    initRealMap();
    tryGeoLocate();
});