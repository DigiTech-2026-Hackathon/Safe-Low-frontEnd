// 백엔드 주소 (실제 서버 구축 후 이 URL을 변경하세요)
const BASE_URL = 'http://localhost:8080/api';

const FAV_STORAGE_KEY = 'flood_risk_favorites'; // F-11: 관심 위치는 서버 API 없이 localStorage에 저장

const appState = {
    currentLat: 37.4842,
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 100',
    currentRainfall: 50,
    currentPattern: '신림',
    mapInstance: null,
    mapMarker: null,
    mapCircle: null,
    shelterMarkers: [],
    gridLayers: [],
    isLlmFailedMode: false
};

// API와 데이터베이스가 연동되기 전까지 임시로 동작하는 Mock 데이터
// (실제 연동 시 /api/risk-score, /api/response-guide 등의 응답으로 대체됩니다)
const mockAddressEngine = {
    '신림': {
        isValidRegion: true,
        score: 85,
        level: '위험',
        warning: '호우경보',
        summary: '반지하 밀집 구역 및 저지대 특성이 겹쳐 집중 강우 시 역류 유입 가능성이 매우 높은 상태입니다.',
        fullDesc: '해당 권역은 누적 점수 85점으로 심각한 위기 상태를 대변하고 있습니다. 지형 계수 조사 결과 주변 지대 대비 약 3m 하강한 저지대 스포크 선상에 위치하고 있으며, 지하 가옥 분배 밀도가 42%에 육박하여 우수 집중 시 최우선 역류 피해가 발생할 수 있는 명확한 근거를 지니고 있습니다.',
        factors: [
            { name: '반지하 가구수', score: 90, percent: 40, desc: '반지하 주거 비율이 관악구 평균 대비 매우 높아 진입 유입에 극도로 취약합니다.' },
            { name: '저지대 지형성', score: 82, percent: 35, desc: '도림천 합류 지점 하단 유출구 정체 시 하수 유입 수위가 비약적으로 증가합니다.' },
            { name: '배수밀도 역량', score: 60, percent: 15, desc: '단시간 처리 가능한 시간당 하수 관거 배출 인프라가 한계 용량에 근접했습니다.' },
            { name: '침수이력 데이터', score: 95, percent: 10, desc: '과거 대형 집중호우 피해 이력이 누적 3회 이상 기록된 요주의 관리 구역입니다.' }
        ],
        shelters: [
            { name: '신림초등학교 체육관', address: '서울시 관악구 신림로 200', capacity: 500, lat: 37.4855, lng: 126.9301 },
            { name: '관악구민회관', address: '서울시 관악구 관악로 145', capacity: 300, lat: 37.4781, lng: 126.9515 }
        ]
    },
    '강남': {
        isValidRegion: true,
        score: 68,
        level: '경고',
        warning: '호우주의보',
        summary: '강남역 사거리 일대는 상습 노면 마루 적체 구간으로 깔때기형 저점 부근입니다.',
        fullDesc: '종합 위험지수 68점으로 경고 단계에 도달했습니다. 주변 지형이 사방에서 모여드는 독특한 깔때기형 배치를 보여 노면 적체가 빠르게 가속되는 특징이 존재하며 고층 빌딩 지하 주차장 진입 구역 차수벽 설치가 필수적인 구조입니다.',
        factors: [
            { name: '반지하 가구수', score: 15, percent: 5, desc: '반지하 가옥은 거의 없으나 지하 주차 시설 중심 유입 위험이 일부 존재합니다.' },
            { name: '저지대 지형성', score: 92, percent: 50, desc: '테헤란로 및 주변 고지대로부터 빗물이 급격히 유입되는 역 마름모형 저점입니다.' },
            { name: '배수밀도 역량', score: 70, percent: 30, desc: '반 배수 처리 역량은 갖추었으나 이물질 유입 시 순간 처리 효율이 급전직하합니다.' },
            { name: '침수이력 데이터', score: 80, percent: 15, desc: '연도별 기습 폭우 사태 시 차량 침수 등 재산 피해 이력이 다수 발견되었습니다.' }
        ],
        shelters: [
            { name: '강남구민체육센터', address: '서울시 강남구 삼성로 200', capacity: 400, lat: 37.4989, lng: 127.0322 }
        ]
    },
    '홍대': {
        isValidRegion: true,
        score: 42,
        level: '주의',
        warning: null,
        summary: '평탄 지형에 속하나 골목길 배수구 막힘 유입 관리가 필요합니다.',
        fullDesc: '분석 결과 종합 점수 42점으로 주의 단계를 나타냅니다. 고도차가 크지 않은 평탄 지형을 이루고 있으나, 상업 시설 밀집 지구 특성상 유동 인구 배출 쓰레기로 인한 배수구 오염 유입 방지책이 지배적인 원인 요인으로 지목됩니다.',
        factors: [
            { name: '반지하 가구수', score: 30, percent: 15, desc: '일부 상업용 지하 근린생활시설 내부 유입 관리가 수반되어야 합니다.' },
            { name: '저지대 지형성', score: 35, percent: 20, desc: '경사 평탄화 분석 결과 지형적 집수 위험 요인은 상당히 낮은 축에 속합니다.' },
            { name: '배수밀도 역량', score: 65, percent: 45, desc: '가장 큰 비중을 차지하는 요인으로 이물질로 인한 일시적 노면 배수 정체가 우려됩니다.' },
            { name: '침수이력 데이터', score: 20, percent: 20, desc: '근래 대규모 침수 피해 및 가옥 파손 접수 이력은 경미한 수준입니다.' }
        ],
        shelters: []
    },
    '독도': {
        isValidRegion: false
    },
    'default': {
        isValidRegion: true,
        score: 15,
        level: '안전',
        warning: null,
        summary: '고도가 확보된 안전 지대이며 기본 관거 시스템 배수 인프라가 대단히 훌륭합니다.',
        fullDesc: '최종 스코어 15점으로 극히 안전한 상태를 보존하고 있습니다. 도시 계획 인프라상 고성능 빗물 펌프 역량이 집중 할당되어 있으며, 자연 경사 배출이 원활하여 극단적 집중 호우 환경 하에서도 탄탄한 방어력을 갖추고 있습니다.',
        factors: [
            { name: '반지하 가구수', score: 5, percent: 5, desc: '권역 내 하층 거주 가구 비율이 거의 전무하다시피 한 구조적 안정 지역입니다.' },
            { name: '저지대 지형성', score: 10, percent: 10, desc: '자연 배수가 즉각 성립되는 평균 이상 고도의 우수한 경사 평면을 보유합니다.' },
            { name: '배수밀도 역량', score: 90, percent: 70, desc: '초당 입방미터급 배출이 보장되는 최신 빗물 저류조 인프라가 조밀하게 확보되었습니다.' },
            { name: '침수이력 데이터', score: 5, percent: 15, desc: '과거 방재 전산망 등록 이래로 범람 내역이 단 한 건도 감지되지 않았습니다.' }
        ],
        shelters: []
    }
};

function showCustomModal(title, message) {
    document.getElementById('modal-title').innerText = title;
    document.getElementById('modal-msg').innerText = message;
    document.getElementById('custom-modal').style.display = 'flex';
}

function hideCustomModal() {
    document.getElementById('custom-modal').style.display = 'none';
}

function initRealMap() {
    if (appState.mapInstance) {
        appState.mapInstance.remove();
    }

    appState.mapInstance = L.map('map-canvas', { zoomControl: false }).setView([appState.currentLat, appState.currentLng], 15);

    // 네이버 지도 스타일의 CartoDB Positron 오픈소스 타일 레이어
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap'
    }).addTo(appState.mapInstance);

    const targetColor = getRiskColor('위험');

    appState.mapCircle = L.circle([appState.currentLat, appState.currentLng], {
        color: targetColor, fillColor: targetColor, fillOpacity: 0.2, radius: 150
    }).addTo(appState.mapInstance);

    appState.mapMarker = L.marker([appState.currentLat, appState.currentLng]).addTo(appState.mapInstance)
        .bindPopup(appState.currentAddress).openPopup();

    document.getElementById('sheet-title-addr').innerText = appState.currentAddress;

    // F-10: 주변 영역 위험도 격자 오버레이 (분석불가 지역 포함)
    renderRiskGrid();
    updateFavToggleUI();
}

/**
 * 진입 시 GPS 권한을 요청해 현재 위치로 이동을 시도한다 (S-01 명세).
 * 실패/거부 시 기본 좌표(신림동)로 유지하고 주소 검색을 유도한다.
 */
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
            appState.currentPattern = 'default';
            initRealMap();
        },
        () => {
            // 거부/실패 시: 기본 위치 유지, 주소 검색 유도
            showCustomModal('위치 확인 불가', 'GPS 권한이 없어 기본 위치로 표시합니다. 상단 검색창에서 주소를 입력해 주세요.');
        },
        { timeout: 5000 }
    );
}

/**
 * 주소/건물명 검색 연동 제어 함수
 */
async function handleSearch() {
    const inputEl = document.getElementById('map-search-input');
    if (!inputEl || !inputEl.value.trim()) {
        showCustomModal('알림', '검색할 주소 또는 건물명을 입력해 주세요.');
        return;
    }

    const keyword = inputEl.value.trim();

    // =========================================================================
    // 실제 백엔드 연동 시 사용할 코드 (API 명세서 기준: GET /api/geocode)
    // 백엔드가 준비되면 아래 주석을 해제하고, 이후의 목업(mock) 매칭 로직은
    // 제거하면 됩니다. 필드명은 API 명세서와 동일하게 맞춰져 있습니다.
    // =========================================================================
    /*
    try {
        const response = await fetch(`${BASE_URL}/geocode?address=${encodeURIComponent(keyword)}`);
        const result = await response.json();

        if (result.success) {
            appState.currentLat = result.data.lat;
            appState.currentLng = result.data.lng;
            appState.currentAddress = result.data.address_road;
            // 좌표 확보 후 /api/risk-score 로 위험 스코어를 조회하는 로직이 이어집니다.
            return;
        }
        showCustomModal('검색 실패', result.error?.message || '주소를 찾을 수 없습니다.');
        return;
    } catch (error) {
        console.error('백엔드 서버 통신 에러: ', error);
        showCustomModal('통신 오류', '서버와 통신할 수 없습니다. 잠시 후 다시 시도해 주세요.');
        return;
    }
    */

    let pattern = 'default';
    if (keyword.includes('신림')) pattern = '신림';
    else if (keyword.includes('강남')) pattern = '강남';
    else if (keyword.includes('홍대')) pattern = '홍대';
    else if (keyword.includes('독도')) pattern = '독도';

    if (pattern === '신림') { appState.currentLat = 37.4842; appState.currentLng = 126.9294; }
    else if (pattern === '강남') { appState.currentLat = 37.4979; appState.currentLng = 127.0276; }
    else if (pattern === '홍대') { appState.currentLat = 37.5565; appState.currentLng = 126.9239; }
    else if (pattern === '독도') { appState.currentLat = 37.2428; appState.currentLng = 131.8689; }
    else { appState.currentLat = 37.5665; appState.currentLng = 126.9780; }

    appState.currentAddress = keyword;
    appState.currentPattern = pattern;
    document.getElementById('sheet-title-addr').innerText = keyword;
    updateFavToggleUI();

    if (appState.mapInstance) {
        const nextTargetPos = [appState.currentLat, appState.currentLng];
        appState.mapInstance.setView(nextTargetPos, 16);

        if (appState.mapMarker) {
            appState.mapMarker.setLatLng(nextTargetPos).bindPopup(keyword).openPopup();
        }
        if (appState.mapCircle) {
            appState.mapCircle.setLatLng(nextTargetPos);
            const initialLevel = mockAddressEngine[pattern].isValidRegion ? mockAddressEngine[pattern].level : '안전';
            const col = getRiskColor(initialLevel);
            appState.mapCircle.setStyle({ color: col, fillColor: col });
        }
    }

    const matchedData = mockAddressEngine[pattern];
    renderWeatherBanner(matchedData.warning);
    renderRiskGrid();
    renderShelters(matchedData.isValidRegion ? matchedData.level : null, matchedData.shelters || []);

    showCustomModal('위치 매핑 완료', `'${keyword}'로 지도 좌표 이동이 완료되었습니다.`);
}

function loadReportApi() {
    const pattern = appState.currentPattern;
    const data = mockAddressEngine[pattern];

    const errorCard = document.getElementById('error-no-data');
    const mainContent = document.getElementById('report-main-content');

    if (!data.isValidRegion) {
        errorCard.style.display = 'block';
        mainContent.style.display = 'none';
        document.getElementById('api-report-addr').innerText = appState.currentAddress;
        return;
    }

    errorCard.style.display = 'none';
    mainContent.style.display = 'block';

    let rainGap = appState.currentRainfall - 50;
    let computedScore = Math.min(100, Math.max(5, data.score + Math.floor(rainGap * 0.4)));

    let computedLevel = '주의';
    if (computedScore <= 25) computedLevel = '안전';
    else if (computedScore <= 50) computedLevel = '주의';
    else if (computedScore <= 75) computedLevel = '경고';
    else computedLevel = '위험';

    if (appState.mapCircle) {
        const dynamicCol = getRiskColor(computedLevel);
        appState.mapCircle.setStyle({ color: dynamicCol, fillColor: dynamicCol });
    }

    document.getElementById('api-report-addr').innerText = appState.currentAddress;
    const reportScoreEl = document.getElementById('api-report-score');
    setTextWithPulse(reportScoreEl, computedScore);

    const gradeEl = document.getElementById('api-report-grade');
    gradeEl.innerText = computedLevel;
    gradeEl.style.color = getRiskColor(computedLevel);

    const gaugeBar = document.getElementById('api-gauge-bar');
    if (gaugeBar) {
        const angle = -45 + (computedScore * 1.8);
        gaugeBar.style.borderColor = getRiskColor(computedLevel);
        gaugeBar.style.transform = `rotate(${angle}deg)`;
    }

    updatePhaseBarHighlight(computedLevel);
    document.getElementById('api-report-summary').innerText = `"${data.summary}"`;

    renderFourFactors(data.factors, rainGap);

    const retryBox = document.getElementById('llm-retry-box');
    const paragraphEl = document.getElementById('api-llm-full-paragraph');

    if (appState.isLlmFailedMode) {
        retryBox.style.display = 'block';
        paragraphEl.innerText = "";
    } else {
        retryBox.style.display = 'none';
        paragraphEl.innerText = data.fullDesc;
    }

    const recalcScoreEl = document.getElementById('api-recalc-score');
    setTextWithPulse(recalcScoreEl, computedScore);
    const recalcGrade = document.getElementById('api-recalc-grade');
    recalcGrade.innerText = computedLevel;
    recalcGrade.style.color = getRiskColor(computedLevel);

    // F-09: 위험 단계가 '경고' 이상으로 재계산되면 대피소 안내도 함께 갱신
    renderShelters(computedLevel, data.shelters || []);
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

function renderFourFactors(factors, rainGap) {
    const listContainer = document.getElementById('api-factor-list');
    if (!listContainer) return;

    listContainer.innerHTML = factors.map(f => {
        let adjustedScore = f.score;
        if (f.name.includes('배수') || f.name.includes('지형')) {
            adjustedScore = Math.min(100, Math.max(0, f.score + Math.floor(rainGap * 0.2)));
        }

        return `
            <div class="factor-card">
                <div class="factor-header">
                    <span class="factor-title">점수 요인: ${f.name}</span>
                    <span class="factor-meta">기여도 <strong style="color:#111;">${f.percent}%</strong> | 요인 스코어: <strong>${adjustedScore}점</strong></span>
                </div>
                <div class="factor-bar-bg">
                    <div class="factor-bar-fill" style="width: ${adjustedScore}%; background: ${getRiskColor(adjustedScore > 70 ? '위험' : adjustedScore > 40 ? '경고' : '안전')};"></div>
                </div>
                <div class="factor-desc"><strong>AI 설명:</strong> ${f.desc}</div>
            </div>
        `;
    }).join('');
}

function retryLLMGeneration() {
    appState.isLlmFailedMode = false;
    showCustomModal('AI 재요청', 'AI 설명 생성을 서버에 다시 요청합니다.');
    loadReportApi();
}

function loadResponseGuideApi() {
    const data = mockAddressEngine[appState.currentPattern];
    if (!data.isValidRegion) {
        renderChecklist('api-guide-list-prep', []);
        document.getElementById('api-guide-list-prep').innerHTML =
            '<div style="font-size:12px; color:#94a3b8;">분석 데이터가 없는 지역입니다. 위험 리포트에서 다른 주소를 검색해 주세요.</div>';
        document.getElementById('evac-guide-box').style.display = 'none';
        document.getElementById('delta-badge').style.display = 'none';
        const chip = document.getElementById('tier-chip');
        if (chip) { chip.innerText = '-'; chip.style.color = '#94a3b8'; chip.style.borderColor = '#94a3b8'; }
        return;
    }

    const currentScore = Number(document.getElementById('api-report-score').innerText) || data.score;

    // 평상시(50mm/h) 기준 스코어 대비 변화량을 배지로 표시
    const baselineScore = data.score;
    const delta = currentScore - baselineScore;
    const deltaEl = document.getElementById('delta-badge');
    if (deltaEl) {
        if (delta === 0) {
            deltaEl.style.display = 'none';
        } else {
            deltaEl.style.display = 'inline-flex';
            deltaEl.style.color = delta > 0 ? '#fca5a5' : '#86efac';
            deltaEl.innerText = delta > 0
                ? `▲ 평상시(50mm/h) 대비 ${delta}점 상승`
                : `▼ 평상시(50mm/h) 대비 ${Math.abs(delta)}점 감소`;
        }
    }

    // 기여도가 가장 큰 위험 요인을 근거로 사전 대비 항목을 지역 맞춤형으로 구성
    const topFactor = [...data.factors].sort((a, b) => b.percent - a.percent)[0];
    const tier = getRainTier(appState.currentRainfall);

    // 강우 구간 칩 갱신 (드래그 시 실시간으로 바뀌는지 눈으로 바로 확인 가능)
    const chipEl = document.getElementById('tier-chip');
    if (chipEl) {
        chipEl.innerText = `${tier.label} · ${appState.currentRainfall}mm/h`;
        chipEl.style.color = tier.color;
        chipEl.style.borderColor = tier.color;
    }

    const prepStepsByTier = {
        calm: [
            `${topFactor.name} 취약 지점을 미리 파악해 두고, 물막이판·모래주머니 보관 위치를 확인하세요.`,
            "배수구·집수정 주변을 정기적으로 점검해 평소 배수 경로를 막힘 없이 유지하세요.",
            "가족과 대피소 위치, 비상연락 방법을 미리 공유해 두세요."
        ],
        watch: [
            `${topFactor.name} 특성상 취약한 출입구·창문 하단에 물막이판을 설치할 준비를 하세요.`,
            "배수구 주변 낙엽·쓰레기를 지금 제거하고 역류방지기 작동 상태를 점검하세요.",
            "휴대전화 보조배터리, 손전등 등 비상용품을 충전해 두세요."
        ],
        warn: [
            `${topFactor.name} 취약 지점에 물막이판과 모래주머니를 지금 바로 설치하세요.`,
            "중요 서류, 가전제품, 귀중품을 높은 곳으로 옮기세요.",
            "차량은 침수 우려가 없는 고지대로 미리 이동해 두세요.",
            "외출을 자제하고 이후 강우 예보와 특보 발령 여부를 계속 확인하세요."
        ],
        extreme: [
            "가전제품 전원을 차단하고 콘센트·멀티탭이 물에 닿지 않도록 조치하세요.",
            "반지하·1층 거주자는 언제든 즉시 이동할 수 있는 상태를 유지하세요.",
            "외출을 금지하고 창문·문틈으로 물이 새는지 수시로 확인하세요.",
            "이웃 중 거동이 불편한 고령자·장애인이 있다면 상황을 미리 확인해 주세요."
        ]
    };

    const evacStepsByTier = {
        calm: [],
        watch: [
            "호우특보 발령 여부를 수시로 확인하고, 우리 집에서 대피소까지 이동 경로를 미리 파악해 두세요."
        ],
        warn: [
            "실내 수위가 발목 높이 이상으로 상승하면 전기 차단기를 내리고 즉시 밖으로 이동하세요.",
            "이동 시 맨홀·배수구 위치를 피하고, 막대 등으로 바닥을 확인하며 이동하세요."
        ],
        extreme: [
            "더 기다리지 말고 즉시 지정 대피소로 이동하세요.",
            "이동이 어렵다면 건물의 가장 높은 층으로 올라가 119·재난안전본부에 구조를 요청하세요.",
            "호우 경보 발효 중에는 하천 변, 지하차도, 지하주차장 근처에 절대 접근하지 마세요."
        ]
    };

    renderChecklist('api-guide-list-prep', prepStepsByTier[tier.key]);

    const evacBox = document.getElementById('evac-guide-box');
    // '경고' 단계 이상이거나 강우 구간이 경보 이상이면 대피 판단 가이드 노출
    if (currentScore >= 51 || tier.key === 'warn' || tier.key === 'extreme') {
        evacBox.style.display = 'block';
        renderChecklist('api-guide-list-evac', evacStepsByTier[tier.key].length ? evacStepsByTier[tier.key] : evacStepsByTier.watch);
    } else {
        evacBox.style.display = 'none';
    }

    const updatedEl = document.getElementById('guide-updated-at');
    if (updatedEl) {
        const now = new Date();
        const hh = String(now.getHours()).padStart(2, '0');
        const mm = String(now.getMinutes()).padStart(2, '0');
        updatedEl.innerText = `업데이트 ${hh}:${mm}`;
    }
}

/**
 * 강우량(mm/h)에 따라 평상시/주의보/경보/극한호우 4단계 구간을 판정한다.
 * 프리셋 버튼(10/50/80/110mm)과 동일한 경계값을 사용한다.
 */
function getRainTier(rainfall) {
    if (rainfall <= 20) return { key: 'calm', label: '평상시', color: '#10b981' };
    if (rainfall <= 60) return { key: 'watch', label: '주의보', color: '#f59e0b' };
    if (rainfall <= 90) return { key: 'warn', label: '경보', color: '#f97316' };
    return { key: 'extreme', label: '극한호우', color: '#ef4444' };
}

/**
 * 체크박스가 있는 대응 안내 리스트를 렌더링한다.
 * 체크 시 취소선으로 완료 표시만 하며(서버 저장 없음), 화면을 벗어나면 초기화된다.
 */
function renderChecklist(containerId, items) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!items || items.length === 0) {
        container.innerHTML = '<div style="font-size:12px; color:#94a3b8;">현재 강우 구간에서는 해당 없음.</div>';
        return;
    }

    container.innerHTML = items.map((text, idx) => `
        <label class="checklist-item">
            <input type="checkbox" onchange="this.parentElement.classList.toggle('done', this.checked)">
            <span class="num-badge">${idx + 1}</span>
            <span class="check-text">${text}</span>
        </label>
    `).join('');
}

function retryResponseGuide() {
    showCustomModal('AI 재생성', '현재 위험 단계와 강우 시나리오를 반영해 대응 안내를 다시 생성했습니다.');
    loadResponseGuideApi();
}

function goToShelterTab() {
    switchView('view1');
    setSheetTab('shelter');
}

function renderWeatherBanner(warningLevel) {
    const bannerEl = document.getElementById('weather-alert-banner');
    if (!bannerEl) return;
    if (warningLevel) {
        bannerEl.innerText = `위험 안내: ${warningLevel} 활성화`;
        bannerEl.style.display = 'inline-flex';
    } else {
        bannerEl.style.display = 'none';
    }
}

/**
 * F-10: 결과 지도 뷰 - 현재 위치 주변을 3x3 격자로 나눠 위험도를 색상으로 표시.
 * 실제 서비스에서는 GET /api/risk-map 의 cells 배열로 대체됩니다.
 * 규칙 기반으로 사전 계산된 값을 사용하는 서버 사양(LLM 미호출)과 동일하게,
 * 여기서도 좌표 기반 규칙만으로 등급을 정하고 임의로 1칸을 '분석불가'로 표시합니다.
 */
function renderRiskGrid() {
    appState.gridLayers.forEach(layer => appState.mapInstance.removeLayer(layer));
    appState.gridLayers = [];

    const step = 0.006; // 격자 한 칸 크기(위경도)
    const levels = ['안전', '주의', '경고', '위험'];
    let cellIndex = 0;
    const analysisGapRow = 1, analysisGapCol = 2; // 분석불가로 표시할 칸(데모용 고정 위치)

    for (let row = -1; row <= 1; row++) {
        for (let col = -1; col <= 1; col++) {
            const isCurrentCell = (row === 0 && col === 0);
            const cLat = appState.currentLat + row * step;
            const cLng = appState.currentLng + col * step;

            const bounds = [
                [cLat - step / 2, cLng - step / 2],
                [cLat + step / 2, cLng + step / 2]
            ];

            let level;
            let isNoData = false;
            if (row === analysisGapRow - 1 && col === analysisGapCol - 1) {
                isNoData = true;
            } else if (isCurrentCell) {
                level = mockAddressEngine[appState.currentPattern].isValidRegion
                    ? mockAddressEngine[appState.currentPattern].level : '안전';
            } else {
                // 중심에서 멀어질수록 위험도가 낮아지는 단순 규칙
                const dist = Math.abs(row) + Math.abs(col);
                level = levels[Math.max(0, 3 - dist)];
            }

            const rect = L.rectangle(bounds, isNoData
                ? { color: '#64748b', weight: 1, fillColor: '#94a3b8', fillOpacity: 0.35, dashArray: '4,3' }
                : { color: getRiskColor(level), weight: 1, fillColor: getRiskColor(level), fillOpacity: isCurrentCell ? 0.05 : 0.22 }
            ).addTo(appState.mapInstance);

            rect.bindPopup(isNoData ? '분석불가 지역: 데이터가 수집되지 않았습니다.' : `격자 위험도: ${level}`);
            appState.gridLayers.push(rect);
            cellIndex++;
        }
    }
}

/**
 * F-09: 대피소 안내 - 위험 단계가 '경고'/'위험'일 때만 인근 대피소를 표시.
 * 실제 서비스에서는 GET /api/shelters(distance_m 포함) 응답으로 대체됩니다.
 */
function renderShelters(riskLevel, shelters) {
    appState.shelterMarkers.forEach(m => appState.mapInstance.removeLayer(m));
    appState.shelterMarkers = [];

    const listEl = document.getElementById('shelter-list');
    const emptyEl = document.getElementById('shelter-empty-msg');
    if (!listEl || !emptyEl) return;

    const shouldShow = (riskLevel === '경고' || riskLevel === '위험') && shelters && shelters.length > 0;

    if (!shouldShow) {
        listEl.innerHTML = '';
        emptyEl.style.display = 'block';
        emptyEl.innerText = (riskLevel === '경고' || riskLevel === '위험')
            ? '반경 내 지정 대피소 정보가 없습니다. 관할 행정복지센터로 문의해 주세요.'
            : "현재 위험 단계가 '경고' 이상일 때 인근 대피소가 표시됩니다.";
        return;
    }

    emptyEl.style.display = 'none';

    const withDistance = shelters.map(s => ({
        ...s,
        distance_m: Math.round(haversineMeters(appState.currentLat, appState.currentLng, s.lat, s.lng))
    })).sort((a, b) => a.distance_m - b.distance_m);

    listEl.innerHTML = withDistance.map(s => `
        <div class="shelter-card">
            <div class="info">
                <span class="name">${s.name}</span>
                <span class="meta">${s.address} · 수용 ${s.capacity}명</span>
            </div>
            <span class="dist">${s.distance_m}m</span>
        </div>
    `).join('');

    withDistance.forEach(s => {
        const marker = L.marker([s.lat, s.lng], {
            icon: L.divIcon({ className: '', html: '<div style="background:#16a34a;color:#fff;font-size:10px;font-weight:bold;padding:3px 6px;border-radius:6px;white-space:nowrap;box-shadow:0 2px 6px rgba(0,0,0,0.25);">대피소</div>' })
        }).addTo(appState.mapInstance).bindPopup(`${s.name} (${s.distance_m}m)`);
        appState.shelterMarkers.push(marker);
    });
}

function haversineMeters(lat1, lng1, lat2, lng2) {
    const R = 6371000;
    const toRad = (v) => (v * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/* ===================== F-11: 관심 위치 저장·모니터링 (localStorage) ===================== */

function getFavorites() {
    try {
        const raw = localStorage.getItem(FAV_STORAGE_KEY);
        return raw ? JSON.parse(raw) : [];
    } catch (e) {
        console.error('관심 위치 데이터를 불러오지 못했습니다: ', e);
        return [];
    }
}

function saveFavorites(list) {
    try {
        localStorage.setItem(FAV_STORAGE_KEY, JSON.stringify(list));
    } catch (e) {
        console.error('관심 위치 데이터를 저장하지 못했습니다: ', e);
    }
}

function isCurrentFavorite() {
    return getFavorites().some(f => f.address === appState.currentAddress);
}

function toggleFavorite() {
    const list = getFavorites();
    const idx = list.findIndex(f => f.address === appState.currentAddress);

    if (idx >= 0) {
        list.splice(idx, 1);
        showCustomModal('관심 위치 해제', `'${appState.currentAddress}'을(를) 관심 위치에서 제거했습니다.`);
    } else {
        list.push({
            address: appState.currentAddress,
            lat: appState.currentLat,
            lng: appState.currentLng,
            pattern: appState.currentPattern
        });
        showCustomModal('관심 위치 저장', `'${appState.currentAddress}'을(를) 관심 위치로 저장했습니다.`);
    }

    saveFavorites(list);
    updateFavToggleUI();
    renderFavorites();
}

function updateFavToggleUI() {
    const btn = document.getElementById('btn-fav-toggle');
    if (!btn) return;
    if (isCurrentFavorite()) {
        btn.innerText = '★ 저장됨';
        btn.classList.add('active');
    } else {
        btn.innerText = '☆ 관심 위치 저장';
        btn.classList.remove('active');
    }
}

function renderFavorites() {
    const listEl = document.getElementById('fav-list');
    const emptyEl = document.getElementById('fav-empty-msg');
    if (!listEl || !emptyEl) return;

    const list = getFavorites();
    if (list.length === 0) {
        listEl.innerHTML = '';
        emptyEl.style.display = 'block';
        return;
    }
    emptyEl.style.display = 'none';

    listEl.innerHTML = list.map((f, idx) => `
        <div class="fav-card">
            <div class="info">
                <span class="name">${f.address}</span>
                <span class="meta">저장된 관심 위치</span>
            </div>
            <div>
                <button class="btn-fav-goto" onclick="goToFavorite(${idx})">조회</button>
                <button class="btn-fav-remove" onclick="removeFavorite(${idx})">삭제</button>
            </div>
        </div>
    `).join('');
}

function goToFavorite(idx) {
    const list = getFavorites();
    const fav = list[idx];
    if (!fav) return;

    appState.currentLat = fav.lat;
    appState.currentLng = fav.lng;
    appState.currentAddress = fav.address;
    appState.currentPattern = fav.pattern;

    document.getElementById('map-search-input').value = fav.address;
    document.getElementById('sheet-title-addr').innerText = fav.address;
    initRealMap();

    const matchedData = mockAddressEngine[fav.pattern];
    renderWeatherBanner(matchedData.warning);
    renderShelters(matchedData.isValidRegion ? matchedData.level : null, matchedData.shelters || []);
    setSheetTab('info');
}

function removeFavorite(idx) {
    const list = getFavorites();
    list.splice(idx, 1);
    saveFavorites(list);
    renderFavorites();
    updateFavToggleUI();
}

function setSheetTab(tab) {
    document.querySelectorAll('.sheet-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.sheet-pane').forEach(p => p.classList.remove('active'));

    document.getElementById(`tab-${tab}`).classList.add('active');
    document.getElementById(`pane-${tab}`).classList.add('active');

    if (tab === 'fav') renderFavorites();
}

let rainDebounceTimer = null;

function updateRainScenario(val) {
    const num = Number(val);
    appState.currentRainfall = num;

    // 슬라이더 라벨은 드래그 중에도 끊김 없이 즉시 갱신
    document.getElementById('slider-val-display').innerText = num + ' mm/h';
    document.getElementById('api-recalc-label').innerText = num + 'mm/h';
    syncSliderPresetActive(num);

    // 점수·지도·체크리스트 재계산은 짧게 묶어서(디바운스) 처리해 드래그 중 버벅임을 줄임
    clearTimeout(rainDebounceTimer);
    rainDebounceTimer = setTimeout(() => {
        loadReportApi();
        loadResponseGuideApi();
    }, 50);
}

function syncSliderPresetActive(val) {
    document.querySelectorAll('.btn-segments .btn-seg').forEach(b => b.classList.remove('active'));
    const matchEl = document.getElementById(`seg-${val}`);
    if (matchEl) matchEl.classList.add('active');
}

function setSlider(val) {
    document.getElementById('rain-slider').value = val;
    updateRainScenario(val);
}

/**
 * 값이 실제로 바뀔 때만 짧은 펄스 애니메이션과 함께 텍스트를 갱신한다.
 * (매번 재생하면 슬라이더 드래그 중 오히려 어지러워 보이므로 변경 시에만 적용)
 */
function setTextWithPulse(el, newValue) {
    if (!el) return;
    const changed = el.innerText !== String(newValue);
    el.innerText = newValue;
    if (changed) {
        el.classList.remove('score-pulse');
        void el.offsetWidth; // 리플로우를 강제해 애니메이션을 재시작
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
    if (viewId === 'view3') { loadReportApi(); loadResponseGuideApi(); }
}

window.onload = () => {
    initRealMap();
    tryGeoLocate();
    const initialData = mockAddressEngine[appState.currentPattern];
    renderWeatherBanner(initialData.warning);
    renderShelters(initialData.isValidRegion ? initialData.level : null, initialData.shelters || []);
};
