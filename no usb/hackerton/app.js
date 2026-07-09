// 백엔드 API 경로.
// Vercel(HTTPS)에 배포된 프론트에서 HTTP 백엔드(http://222.110.147.56:5000)를 직접 호출하면
// Mixed Content로 차단되므로, 절대경로 대신 같은 오리진의 상대경로 '/api'를 사용한다.
// 실제 백엔드로의 전달은 vercel.json의 rewrites 설정이 처리한다 (same-origin 프록시).
const BASE_URL = '/api';

const FAV_STORAGE_KEY = 'flood_risk_favorites';

const appState = {
    currentLat: 37.4842,
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 100',
    currentRainfall: 50,
    currentLevel: '안전',       // 실시간 위험 단계(risk_level) 저장용
    currentBuildingId: null,   // risk-score find-or-create 결과 재사용 (재계산 시 lat/lng 대신 사용)
    currentScoreId: null,      // 최근 risk-score의 score_id (response-guide 호출 시 필수)
    lastFactors: [],           // 최근 risk-score 요인분해 결과
    mapInstance: null,
    mapMarker: null,
    mapCircle: null,
    shelterMarkers: [],
    gridLayers: [],
    gridRequestId: 0
};

/**
 * fetch 응답을 JSON으로 안전하게 파싱한다.
 * 백엔드가 502/504 등으로 죽어있으면 Vercel이 JSON이 아닌 HTML/텍스트 에러 페이지를
 * 대신 내려주는데, 이때 response.json()이 SyntaxError를 던지며 콘솔에 원인이 불분명한
 * 에러만 남는다. 이 헬퍼로 그 경우를 "백엔드 연결 실패"로 명확히 구분한다.
 */
async function safeParseJson(response) {
    const text = await response.text();
    try {
        return { json: JSON.parse(text), backendUnreachable: false };
    } catch (e) {
        console.error('JSON 파싱 실패 (백엔드가 응답하지 않음/프록시 오류로 추정):', text.slice(0, 200));
        return { json: null, backendUnreachable: true };
    }
}

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
    // 인라인 스타일(.style.bottom)이 CSS 규칙을 방해하지 않도록 완전히 제거합니다.
    const geoBtn = document.getElementById('geo-btn');
    if (geoBtn) {
        geoBtn.style.bottom = '';
    }
}

// 위치가 바뀔 때마다 이전 위치의 building_id/score_id/요인 캐시를 초기화
function resetLocationBoundState() {
    appState.currentBuildingId = null;
    appState.currentScoreId = null;
    appState.lastFactors = [];
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
 */
async function handleSearch() {
    const inputEl = document.getElementById('map-search-input');
    if (!inputEl || !inputEl.value.trim()) {
        showCustomModal('알림', '검색할 주소 또는 건물명을 입력해 주세요.');
        return;
    }

    const keyword = inputEl.value.trim();

    try {
        const response = await fetch(`${BASE_URL}/geocode?address=${encodeURIComponent(keyword)}`);
        const { json: resJson, backendUnreachable } = await safeParseJson(response);

        if (backendUnreachable) {
            showCustomModal('백엔드 연결 실패', '백엔드 서버(/api)에 연결할 수 없습니다. 서버가 켜져 있는지, 외부에서 접속 가능한지 확인해 주세요.');
            return;
        }

        if (response.status === 404) {
            showCustomModal('검색 결과 없음', resJson.error?.message || '해당 주소/건물명을 찾을 수 없습니다.');
            return;
        }
        if (!response.ok || resJson.success === false) {
            showCustomModal('검색 실패', resJson.error?.message || '해당 주소/건물명을 찾을 수 없습니다.');
            return;
        }

        const geo = resJson.data;

        appState.currentLat = geo.lat;
        appState.currentLng = geo.lng;
        appState.currentAddress = geo.address_road || geo.address_jibun || geo.address || keyword;
        resetLocationBoundState();

        document.getElementById('sheet-title-addr').innerText = appState.currentAddress;
        updateFavToggleUI();

        if (appState.mapInstance) {
            appState.mapInstance.setView([appState.currentLat, appState.currentLng], 16);
            updateMapLayers(appState.currentLat, appState.currentLng, '안전', appState.currentAddress);
        }

        renderRiskGrid();
        showCustomModal('위치 매핑 완료', `'${appState.currentAddress}'로 이동되었습니다. 아래에서 리포트를 확인하세요.`);
    } catch (error) {
        console.error(error);
        showCustomModal('서버 오류', '위치 지오코딩 중 서버 오류가 발생했습니다.');
    }
}

/**
 * POST /api/risk-score 공통 호출 헬퍼 (API 명세서 기준).
 * building_id가 있으면 재계산(find-or-create의 재계산 경로), 없으면 lat/lng로 최초 조회.
 * 성공 시 appState(currentBuildingId/currentScoreId/currentLevel/lastFactors)를 갱신한다.
 *
 * 응답 예:
 * { success:true, data:{ score_id, building:{building_id,...}, total_score, risk_level,
 *   rainfall_scenario, summary, factors:[{factor_type,contribution,description}], created_at } }
 */
async function fetchRiskScore(rainfallScenario) {
    const body = appState.currentBuildingId
        ? { building_id: appState.currentBuildingId, rainfall_scenario: rainfallScenario }
        : { lat: appState.currentLat, lng: appState.currentLng, rainfall_scenario: rainfallScenario };

    let response;
    try {
        response = await fetch(`${BASE_URL}/risk-score`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
    } catch (error) {
        console.error('risk-score 통신 실패:', error);
        return { ok: false, notCovered: false, llmFailed: false };
    }

    // 422 = 분석 불가 지역(데이터 미커버)
    if (response.status === 422) {
        return { ok: false, notCovered: true, llmFailed: false };
    }
    // 503 = LLM 호출 실패
    if (response.status === 503) {
        return { ok: false, notCovered: false, llmFailed: true };
    }
    if (!response.ok) {
        return { ok: false, notCovered: false, llmFailed: false };
    }

    const { json: resJson, backendUnreachable } = await safeParseJson(response);
    if (backendUnreachable || !resJson) {
        return { ok: false, notCovered: false, llmFailed: false, backendUnreachable: true };
    }
    if (resJson.success === false) {
        return { ok: false, notCovered: false, llmFailed: false };
    }

    const data = resJson.data;

    appState.currentBuildingId = data.building?.building_id ?? null;
    appState.currentScoreId = data.score_id ?? null;
    appState.currentLevel = data.risk_level;
    appState.lastFactors = data.factors || [];

    return { ok: true, data };
}

/**
 * [연동] 화면2(위험 리포트) 데이터 로드
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
            if (result.backendUnreachable) {
                showCustomModal('백엔드 연결 실패', '백엔드 서버(/api)에 연결할 수 없습니다. 서버가 켜져 있는지, 외부에서 접속 가능한지 확인해 주세요.');
            } else if (result.llmFailed) {
                showCustomModal('AI 분석 실패', 'AI 위험도 분석 서버 호출에 실패했습니다. 잠시 후 다시 시도해 주세요.');
            }
            return;
        }

        const data = result.data;
        errorCard.style.display = 'none';
        mainContent.style.display = 'block';

        updateMapLayers(appState.currentLat, appState.currentLng, data.risk_level, appState.currentAddress);

        // 상단 날씨 배너: risk-score 응답엔 특보 정보가 없어 /api/rainfall을 별도 호출
        loadWeatherBanner();

        const reportScoreEl = document.getElementById('api-report-score');
        setTextWithPulse(reportScoreEl, data.total_score);

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

        // 요인 분해 데이터 리스트 렌더링
        renderFourFactors(data.factors || []);

        // 명세서상 risk-score 응답엔 별도의 '종합 설명(full_desc)' 필드가 없어
        // summary를 종합 설명 영역에도 재사용한다. 재시도 버튼은 숨김 처리.
        const retryBox = document.getElementById('llm-retry-box');
        const paragraphEl = document.getElementById('api-llm-full-paragraph');
        retryBox.style.display = 'none';
        paragraphEl.innerText = data.summary || "";

        const recalcScoreEl = document.getElementById('api-recalc-score');
        setTextWithPulse(recalcScoreEl, data.total_score);
        const recalcGrade = document.getElementById('api-recalc-grade');
        recalcGrade.innerText = data.risk_level;
        recalcGrade.style.color = getRiskColor(data.risk_level);

        // 대피소: risk-score 응답엔 없어 /api/shelters를 별도 호출 (F-09, 경고/위험 단계에서만)
        loadShelters(data.risk_level);

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
        const contribution = f.contribution ?? 0;
        const barLevel = contribution > 30 ? '위험' : contribution > 15 ? '경고' : '안전';
        return `
            <div class="factor-card">
                <div class="factor-header">
                    <span class="factor-title">점수 요인: ${f.factor_type}</span>
                    <span class="factor-meta">기여도 <span class="factor-percent-highlight">${contribution}%</span></span>
                </div>
                <div class="factor-bar-bg">
                    <div class="factor-bar-fill" style="width: ${contribution}%; background: ${getRiskColor(barLevel)};"></div>
                </div>
                <div class="factor-desc"><strong>AI 설명:</strong> ${f.description}</div>
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
    document.getElementById('api-guide-addr').innerText = appState.currentAddress;

    try {
        // 강우 시나리오 변경분을 먼저 risk-score에 반영해 점수/단계 및 score_id를 최신화
        const scoreResult = await fetchRiskScore(appState.currentRainfall);
        if (!scoreResult.ok) {
            if (scoreResult.backendUnreachable) {
                showCustomModal('백엔드 연결 실패', '백엔드 서버(/api)에 연결할 수 없습니다. 서버가 켜져 있는지, 외부에서 접속 가능한지 확인해 주세요.');
            } else if (scoreResult.llmFailed) {
                showCustomModal('AI 분석 실패', 'AI 위험도 재계산에 실패했습니다. 잠시 후 다시 시도해 주세요.');
            } else if (scoreResult.notCovered) {
                showCustomModal('분석 불가 지역', '해당 구역은 침수 분석 정보가 수집되지 않는 구역입니다.');
            }
            return;
        }

        const d = scoreResult.data;
        setTextWithPulse(document.getElementById('api-recalc-score'), d.total_score);
        const recalcGrade = document.getElementById('api-recalc-grade');
        recalcGrade.innerText = d.risk_level;
        recalcGrade.style.color = getRiskColor(d.risk_level);

        if (!appState.currentScoreId) throw new Error('score_id 없음');

        const response = await fetch(`${BASE_URL}/response-guide`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ score_id: appState.currentScoreId })
        });

        if (response.status === 503) {
            showCustomModal('AI 분석 실패', 'AI 대응 안내 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.');
            return;
        }
        if (!response.ok) throw new Error('가이드 조회 실패');

        const { json: resJson, backendUnreachable } = await safeParseJson(response);
        if (backendUnreachable || !resJson || resJson.success === false) throw new Error('가이드 조회 실패');
        const data = resJson.data;

        const chip = document.getElementById('tier-chip');
        if (chip) {
            chip.innerText = `${data.risk_level} 단계 행동 요령`;
            chip.style.color = '#fff';
            chip.style.background = getRiskColor(data.risk_level);
            chip.style.borderColor = getRiskColor(data.risk_level);
        }

        // 명세서 response-guide 응답엔 기준(50mm) 대비 편차(rain_gap) 필드가 없어
        // 슬라이더 기준값(50mm) 대비 편차를 프론트에서 직접 계산해 배지로 표시한다.
        const deltaBadge = document.getElementById('delta-badge');
        const rainGap = appState.currentRainfall - 50;
        if (rainGap !== 0) {
            deltaBadge.innerText = rainGap > 0 ? `기준 대비 +${rainGap}mm` : `기준 대비 ${rainGap}mm`;
            deltaBadge.style.display = 'inline-block';
        } else {
            deltaBadge.style.display = 'none';
        }

        // 명세서 response-guide는 사전 준비/대피 판단을 구분하지 않고 guides 배열 하나만 준다.
        // '대피' 관련 키워드가 포함된 항목을 대피 판단 가이드로, 나머지를 사전 준비 가이드로 분류해
        // S-03 화면 명세(사전 준비 카드 + 대피 판단 카드)를 재현한다.
        const { prep, evac } = splitGuidesByEvac(data.guides || []);
        renderChecklist('api-guide-list-prep', prep.length ? prep : (data.guides || []));

        const evacBox = document.getElementById('evac-guide-box');
        const isHighRisk = d.risk_level === '경고' || d.risk_level === '위험';
        if (isHighRisk && evac.length > 0) {
            renderChecklist('api-guide-list-evac', evac);
            evacBox.style.display = 'block';
        } else {
            evacBox.style.display = 'none';
        }

    } catch (error) {
        console.error(error);
    }
}

/**
 * response-guide의 flat한 guides 배열을 대피 관련 키워드 유무로 분류한다.
 * (백엔드가 prep/evac 카테고리를 분리해서 주지 않으므로 프론트에서 휴리스틱으로 구분)
 */
function splitGuidesByEvac(guides) {
    const evacKeywords = ['대피', '이동하세요', '이동해', '대피소'];
    const prep = [];
    const evac = [];
    guides.forEach(g => {
        if (evacKeywords.some(k => g.includes(k))) {
            evac.push(g);
        } else {
            prep.push(g);
        }
    });
    return { prep, evac };
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

    // 슬라이더 드래그 중 과도한 API 호출을 막기 위한 디바운스
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

/**
 * [연동] GET /api/risk-map 호출로 지도 영역 격자 위험도를 한 번에 조회한다.
 * 규칙 기반 사전 계산값이라 LLM을 타지 않고 빠르며, risk-score처럼 "시범 구역
 * 등록 건물"로 커버리지가 제한되지 않는다(F-10 전용 엔드포인트).
 */
async function renderRiskGrid() {
    if (!appState.mapInstance) return;
    appState.gridLayers.forEach(layer => appState.mapInstance.removeLayer(layer));
    appState.gridLayers = [];

    // 검색이 연달아 일어날 경우, 늦게 도착한 이전 요청 결과가 최신 화면을 덮어쓰지 않도록
    // 이번 렌더링 회차를 식별하는 토큰을 발급한다.
    const requestId = ++appState.gridRequestId;

    const centerLat = appState.currentLat;
    const centerLng = appState.currentLng;
    const halfSpan = 0.0045; // 기존 3x3(0.003 간격) 격자와 비슷한 범위를 커버
    const cellSize = 0.003;  // 명세서에 셀 크기가 명시돼 있지 않아 표시용으로 기존 크기 재사용

    try {
        const params = new URLSearchParams({
            min_lat: centerLat - halfSpan,
            min_lng: centerLng - halfSpan,
            max_lat: centerLat + halfSpan,
            max_lng: centerLng + halfSpan
        });

        const response = await fetch(`${BASE_URL}/risk-map?${params.toString()}`);

        // 조회하는 동안 다른 위치 검색이 실행됐다면 이 결과는 폐기(구버전 렌더링 방지)
        if (requestId !== appState.gridRequestId) return;

        if (!response.ok) return;
        const resJson = await response.json();
        if (resJson.success === false) return;

        const cells = resJson.data?.cells || [];

        cells.forEach(cell => {
            const col = getRiskColor(cell.risk_level);
            const rect = L.rectangle([
                [cell.lat - cellSize / 2, cell.lng - cellSize / 2],
                [cell.lat + cellSize / 2, cell.lng + cellSize / 2]
            ], {
                color: col, weight: 1, fillColor: col, fillOpacity: 0.15
            }).addTo(appState.mapInstance);

            appState.gridLayers.push(rect);
        });
    } catch (error) {
        console.error('격자 위험도 조회 실패:', error);
    }
}

/**
 * [연동] GET /api/rainfall 호출로 현재 위치의 실시간 기상특보를 조회해
 * 상단 배너에 반영한다 (risk-score 응답엔 특보 정보가 없어 별도 호출 필요).
 */
async function loadWeatherBanner() {
    try {
        const params = new URLSearchParams({ lat: appState.currentLat, lng: appState.currentLng });
        const response = await fetch(`${BASE_URL}/rainfall?${params.toString()}`);
        if (!response.ok) { renderWeatherBanner(null); return; }
        const resJson = await response.json();
        if (resJson.success === false) { renderWeatherBanner(null); return; }
        renderWeatherBanner(resJson.data?.warning_level || null);
    } catch (error) {
        console.error('강우 특보 조회 실패:', error);
        renderWeatherBanner(null);
    }
}

/**
 * [연동] GET /api/shelters 호출로 인근 대피소를 조회한다.
 * F-09 정책상 '경고' 이상 단계에서만 조회(risk-score 응답엔 대피소 정보가 없어 별도 호출).
 */
async function loadShelters(level) {
    if (level !== '경고' && level !== '위험') {
        renderShelters(level, []);
        return;
    }
    try {
        const params = new URLSearchParams({ lat: appState.currentLat, lng: appState.currentLng });
        const response = await fetch(`${BASE_URL}/shelters?${params.toString()}`);
        if (response.status === 404) { renderShelters(level, []); return; }
        if (!response.ok) { renderShelters(level, []); return; }
        const resJson = await response.json();
        if (resJson.success === false) { renderShelters(level, []); return; }
        renderShelters(level, resJson.data?.shelters || []);
    } catch (error) {
        console.error('대피소 조회 실패:', error);
        renderShelters(level, []);
    }
}

function renderShelters(currentLevel, shelters) {
    if (!appState.mapInstance) return;
    appState.shelterMarkers.forEach(m => appState.mapInstance.removeLayer(m));
    appState.shelterMarkers = [];

    const emptyMsg = document.getElementById('shelter-empty-msg');
    const listContainer = document.getElementById('shelter-list');

    if (!currentLevel || (currentLevel !== '경고' && currentLevel !== '위험') || !shelters || shelters.length === 0) {
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
        }).addTo(appState.mapInstance).bindPopup(`<b>${s.shelter_name}</b><br>${s.address}`);

        appState.shelterMarkers.push(marker);
    });

    if (listContainer) {
        listContainer.innerHTML = shelters.map(s => `
            <div class="shelter-card">
                <div class="shelter-name">🏡 ${s.shelter_name}</div>
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
    } else if (tabId === 'history') {
        document.getElementById('tab-history').classList.add('active');
        document.getElementById('pane-history').classList.add('active');
        loadHistoryApi();
    }
}

/**
 * [연동] GET /api/history 호출로 최근 조회 기록(risk_score 이력, 최신순)을 불러온다.
 */
async function loadHistoryApi() {
    const listContainer = document.getElementById('history-list');
    const emptyMsg = document.getElementById('history-empty-msg');
    if (!listContainer) return;

    try {
        const params = new URLSearchParams({ limit: 20 });
        const response = await fetch(`${BASE_URL}/history?${params.toString()}`);
        const { json: resJson, backendUnreachable } = await safeParseJson(response);

        if (backendUnreachable || !response.ok || !resJson || resJson.success === false) {
            renderHistoryList([]);
            return;
        }

        renderHistoryList(resJson.data?.history || []);
    } catch (error) {
        console.error('조회 이력 로드 실패:', error);
        renderHistoryList([]);
    }
}

function renderHistoryList(history) {
    const listContainer = document.getElementById('history-list');
    const emptyMsg = document.getElementById('history-empty-msg');
    if (!listContainer) return;

    if (!history || history.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        listContainer.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';

    listContainer.innerHTML = history.map(h => {
        const dateText = h.created_at ? new Date(h.created_at).toLocaleString('ko-KR') : '';
        const levelColor = getRiskColor(h.risk_level);
        return `
            <div class="history-item-row">
                <div class="history-item-main">
                    <span class="history-addr">${h.address_road || '주소 정보 없음'}</span>
                    <span class="history-level-badge" style="background:${levelColor}">${h.risk_level ?? '-'}</span>
                </div>
                <div class="history-meta">점수 ${h.total_score ?? '-'}점 · 강우 ${h.rainfall_scenario ?? '-'}mm · ${dateText}</div>
            </div>
        `;
    }).join('');
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
    if (level === '위험') return '#ef4444';
    return '#94a3b8'; // 분석불가 / 알 수 없음
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
