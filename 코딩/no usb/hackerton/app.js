// 백엔드 주소 (실제 서버 구축 후 이 URL을 변경하세요)
const BASE_URL = 'http://localhost:8080/api';

const appState = {
    currentLat: 37.4842, 
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 100',
    currentRainfall: 50,
    mapInstance: null,
    mapMarker: null,
    mapCircle: null,
    isLlmFailedMode: false 
};

// API와 데이터베이스가 연동되기 전까지 임시로 동작하는 Mock 데이터
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
        ]
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
        ]
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
    // 백엔드 API & DB 실제 연동 시 개발 가이드 가상 스니펫
    // (백엔드가 완성되면 아래 주석 코드를 풀어서 변수를 바인딩하면 됩니다)
    // =========================================================================
    /*
    try {
        // 1. 검색어(건물명/주소)를 인코딩하여 데이터베이스에 분석 쿼리 요청
        const response = await fetch(`${BASE_URL}/flood-risk?keyword=${encodeURIComponent(keyword)}&rainfall=${appState.currentRainfall}`);
        const result = await response.json();
        
        if (result.success) {
            // DB에서 가져온 실제 위경도 정보 적용
            appState.currentLat = result.data.latitude;
            appState.currentLng = result.data.longitude;
            appState.currentAddress = result.data.addressName;
            
            // 데이터 매핑 및 지도 갱신 로직 실행...
            return;
        }
    } catch (error) {
        console.error("백엔드 서버 통신 에러: ", error);
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
    document.getElementById('sheet-title-addr').innerText = keyword;

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

    showCustomModal('위치 매핑 완료', `'${keyword}'로 지도 좌표 이동이 완료되었습니다.`);
}

function loadReportApi() {
    let pattern = 'default';
    if (appState.currentAddress.includes('신림')) pattern = '신림';
    else if (appState.currentAddress.includes('강남')) pattern = '강남';
    else if (appState.currentAddress.includes('홍대')) pattern = '홍대';
    else if (appState.currentAddress.includes('독도')) pattern = '독도';

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
    document.getElementById('api-report-score').innerText = computedScore;
    
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

    document.getElementById('api-recalc-score').innerText = computedScore;
    const recalcGrade = document.getElementById('api-recalc-grade');
    recalcGrade.innerText = computedLevel;
    recalcGrade.style.color = getRiskColor(computedLevel);
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
        if(f.name.includes('배수') || f.name.includes('지형')) {
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
                <div class="factor-desc"><strong>LLM 설명 (F-06):</strong> ${f.desc}</div>
            </div>
        `;
    }).join('');
}

function retryLLMGeneration() {
    appState.isLlmFailedMode = false; 
    showCustomModal('LLM 통신 재시도', '언어 모델 요약을 백엔드 서버에 재요청합니다.');
    loadReportApi();
}

function loadResponseGuideApi() {
    const container = document.getElementById('api-guide-list');
    let currentScore = Number(document.getElementById('api-report-score').innerText) || 50;

    let steps = [
        "지하 진입로 인근 물막이판 지지 구조대를 결속하십시오.",
        "인근 침수 우려 배수 홈통 주변 잔해물을 신속히 수거하세요."
    ];

    if (currentScore >= 75) {
        steps.push("현재 수위 상승 징후가 현저하오니 가차 없이 대피 경로를 타고 고지대로 탈출하십시오.");
    } else {
        steps.push("안내 방송 인프라 소통 경로를 개방한 채 안전 기상 예보 추이를 상시 대기 관측하세요.");
    }

    container.innerHTML = steps.map((text, idx) => `
        <div class="action-item">
            <span class="num-badge">${idx + 1}</span>
            ${text}
        </div>
    `).join('');
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

function updateRainScenario(val) {
    appState.currentRainfall = Number(val);
    document.getElementById('slider-val-display').innerText = val + ' mm/h';
    document.getElementById('api-recalc-label').innerText = val + 'mm/h';
    loadReportApi();
}

function setSlider(val) {
    document.getElementById('rain-slider').value = val;
    document.querySelectorAll('.btn-segments .btn-seg').forEach(b => b.classList.remove('active'));
    document.getElementById(`seg-${val}`).classList.add('active');
    updateRainScenario(val);
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

window.onload = () => {
    initRealMap();
};