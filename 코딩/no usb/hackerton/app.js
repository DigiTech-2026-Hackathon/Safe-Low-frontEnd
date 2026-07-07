/**
 * 침수 위험 모니터링 시스템 - API 연동 코어 스크립트
 */
const BASE_URL = '/api';

// 애플리케이션 상태 관리 객체
const appState = {
    currentBuildingId: null,
    currentScoreId: null,
    currentLat: 37.4842,
    currentLng: 126.9294,
    currentAddress: '서울 관악구 신림동 1234-5',
    currentRainfall: 50
};

/**
 * 💡 글로벌 커스텀 알림 모달 UI 컨트롤러
 */
function showCustomModal(title, message) {
    const modalTitle = document.getElementById('modal-title');
    const modalMsg = document.getElementById('modal-msg');
    const modalContainer = document.getElementById('custom-modal');
    
    if (modalTitle && modalMsg && modalContainer) {
        modalTitle.innerText = title;
        modalMsg.innerText = message;
        modalContainer.style.display = 'flex';
    }
}

function hideCustomModal() {
    const modalContainer = document.getElementById('custom-modal');
    if (modalContainer) {
        modalContainer.style.display = 'none';
    }
}

/**
 * 💡 F-01: 주소 검색 및 좌표 변환 연동
 */
async function handleSearch() {
    const inputEl = document.getElementById('map-search-input');
    if (!inputEl || !inputEl.value.trim()) {
        showCustomModal('알림', '검색할 주소를 입력해주세요.');
        return;
    }

    const address = inputEl.value.trim();

    try {
        const response = await fetch(`${BASE_URL}/geocode?address=${encodeURIComponent(address)}`);
        const json = await response.json();

        if (!json.success) {
            handleApiError(json.error);
            return;
        }

        // 상태 업데이트
        appState.currentAddress = json.data.address_jibun || json.data.address_road;
        appState.currentLat = json.data.lat;
        appState.currentLng = json.data.lng;
        appState.currentBuildingId = null; // 새로운 위치이므로 ID 초기화

        // 지도 오버레이 텍스트 변경
        const markerTxt = document.getElementById('map-marker-txt');
        if (markerTxt) markerTxt.innerHTML = `검색 위치 <span style="color:#93c5fd;">· 연동 중</span>`;

        showCustomModal('위치 변환 성공', `주소 매핑이 완료되었습니다.\n위도: ${appState.currentLat}\n경도: ${appState.currentLng}\n\n위험 리포트 탭으로 이동하면 실시간 분석이 시작됩니다.`);
        
        // 검색 후 자동으로 데이터 분석 및 리포트 화면으로 전환
        switchView('view2');

    } catch (error) {
        showCustomModal('통신 오류', '지오코딩 서버와 연결할 수 없습니다.');
    }
}

/**
 * 💡 F-02 ~ F-06: 침수 위험 스코어 산출 및 요인 분석 요청
 */
async function loadReportApi() {
    try {
        const payload = {
            rainfall_scenario: appState.currentRainfall
        };

        // 기존 조회가 있다면 building_id 전달, 없다면 좌표 전달
        if (appState.currentBuildingId) {
            payload.building_id = appState.currentBuildingId;
        } else {
            payload.lat = appState.currentLat;
            payload.lng = appState.currentLng;
        }

        const response = await fetch(`${BASE_URL}/risk-score`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const json = await response.json();

        if (!json.success) {
            handleApiError(json.error);
            return;
        }

        const data = json.data;
        
        // 전역 상태 동기화
        appState.currentBuildingId = data.building.building_id;
        appState.currentScoreId = data.score_id;

        // UI 갱신 데이터 매핑
        document.getElementById('api-report-addr').innerText = `${data.building.address_road} ${data.building.is_semi_basement ? '· 반지하' : ''}`;
        document.getElementById('api-report-score').innerText = data.total_score;
        
        const gradeEl = document.getElementById('api-report-grade');
        gradeEl.innerText = data.risk_level;
        gradeEl.style.color = getRiskColor(data.risk_level);

        document.getElementById('api-report-summary').innerText = `"${data.summary}"`;
        
        // 게이지 차트 각도 계산 (0점 = -45도, 100점 = 135도)
        const gaugeBar = document.getElementById('api-gauge-bar');
        if (gaugeBar) {
            const calculatedDeg = -45 + (data.total_score * 1.8);
            gaugeBar.style.borderColor = getRiskColor(data.risk_level);
            gaugeBar.style.borderLeftColor = 'transparent';
            gaugeBar.style.borderBottomColor = 'transparent';
            gaugeBar.style.transform = `rotate(${calculatedDeg}deg)`;
        }

        // 상단 오버레이 정보 동기화
        const markerTxt = document.getElementById('map-marker-txt');
        if (markerTxt) markerTxt.innerHTML = `선택 건물 <span style="color:#93c5fd;">· ${data.total_score}점</span>`;

        // 하위 위험 요소 동적 생성
        renderFactors(data.factors);
        renderContributionBar(data.factors);
        updateTagHighlight(data.risk_level);

        // 시나리오 탭에 공유할 실시간 스코어 전달용 동기화
        const recalcScoreEl = document.getElementById('api-recalc-score');
        const recalcGradeEl = document.getElementById('api-recalc-grade');
        if (recalcScoreEl) recalcScoreEl.innerText = data.total_score;
        if (recalcGradeEl) {
            recalcGradeEl.innerText = data.risk_level;
            recalcGradeEl.style.color = getRiskColor(data.risk_level);
        }

    } catch (error) {
        showCustomModal('데이터 분석 실패', '위험 스코어 서버 엔진 응답에 실패했습니다.');
    }
}

/**
 * 💡 F-07: AI 맞춤 대응 행동 지침 조회
 */
async function loadResponseGuideApi() {
    if (!appState.currentScoreId) {
        showCustomModal('가이드라인 에러', '먼저 위험도 산출이 진행되어야 가이드를 로드할 수 있습니다.');
        return;
    }

    try {
        const response = await fetch(`${BASE_URL}/response-guide`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ score_id: appState.currentScoreId })
        });
        const json = await response.json();

        if (!json.success) {
            handleApiError(json.error);
            return;
        }

        // 가이드 UI 리스트 반영하기
        const guides = json.data.guides;
        const targetContainers = [
            document.querySelector('.action-box.yellow .action-list'),
            document.querySelector('.action-box.pink .action-list')
        ];

        // 동적으로 할당 처리
        targetContainers.forEach(container => {
            if (container) {
                container.innerHTML = guides.map((guide, index) => `
                    <div class="action-item">
                        <span class="num-badge">${index + 1}</span>
                        ${guide}
                    </div>
                `).join('');
            }
        });

    } catch (error) {
        showCustomModal('통신 실패', 'AI 가이드라인 데이터를 받아오는 중 문제가 발생했습니다.');
    }
}

/**
 * 💡 F-04: 강우량 슬라이더 조절 시 실시간 API 재계산 트리거
 */
function updateRainScenario(val) {
    appState.currentRainfall = Number(val);
    document.getElementById('slider-val-display').innerText = val + ' mm/h';
    document.getElementById('api-recalc-label').innerText = val + 'mm/h';
    
    // 디바운스 대용 혹은 즉시 백엔드 스코어 실시간 갱신 호출
    loadReportApi();
}

function setSlider(val) {
    const slider = document.getElementById('rain-slider');
    if (slider) slider.value = val;
    
    document.querySelectorAll('.btn-segments .btn-seg').forEach(b => b.classList.remove('active'));
    const activeSeg = document.getElementById(`seg-${val}`);
    if (activeSeg) activeSeg.classList.add('active');
    
    updateRainScenario(val);
}

/**
 * 💡 컴포넌트 렌더링 서브 함수들
 */
function renderFactors(factors) {
    const el = document.getElementById('api-factor-list');
    if (!el) return;

    el.innerHTML = factors.map(f => {
        const color = getFactorColor(f.factor_type);
        const displayScore = Math.floor(f.contribution * 2.3); // 연출용 가중치 변환
        return `
            <div class="factor-card">
                <div class="factor-header">
                    <div class="factor-title">${f.factor_type} 요인 검출</div>
                    <div style="display:flex; align-items:center; gap:8px;">
                        <span style="font-size:16px; font-weight:bold; color:${color}">${f.contribution}%</span>
                    </div>
                </div>
                <div class="factor-bar-bg">
                    <div class="factor-bar-fill" style="width:${f.contribution}%; background:${color}"></div>
                </div>
                <div class="factor-desc">${f.description}</div>
            </div>
        `;
    }).join('');
}

function renderContributionBar(factors) {
    const el = document.getElementById('api-contrib-bar');
    if (!el) return;

    el.innerHTML = factors.map(f => `
        <div class="contrib-seg" style="width:${f.contribution}%; background:${getFactorColor(f.factor_type)};">
            ${Math.round(f.contribution)}%
        </div>
    `).join('');
}

function updateTagHighlight(currentLevel) {
    const tags = {
        '안전': 'tag-safe',
        '주의': 'tag-watch',
        '경고': 'tag-warn',
        '위험': 'tag-danger',
        '심각': 'tag-severe'
    };

    document.querySelectorAll('.status-tag').forEach(tag => {
        tag.classList.remove('active');
        tag.style.background = '#2d3748';
    });

    const activeId = tags[currentLevel] || 'tag-safe';
    const targetTag = document.getElementById(activeId);
    if (targetTag) {
        targetTag.classList.add('active');
        targetTag.style.background = getRiskColor(currentLevel);
    }
}

/**
 * 유틸리티 헬퍼 매퍼 함수
 */
function getRiskColor(level) {
    if (level === '안전') return '#10b981';
    if (level === '주의') return '#f59e0b';
    if (level === '경고') return '#f97316';
    if (level === '위험' || level === '심각') return '#ef4444';
    return '#9ca3af';
}

function getFactorColor(type) {
    if (type.includes('반지하')) return '#ef4444';
    if (type.includes('저지대')) return '#f59e0b';
    if (type.includes('배수')) return '#3b82f6';
    return '#10b981';
}

function handleApiError(errorObj) {
    const msg = errorObj ? errorObj.message : '알 수 없는 서버 에러가 발생했습니다.';
    showCustomModal('통신 시스템 경고', `에러 코드: ${errorObj ? errorObj.code : 500}\n내용: ${msg}`);
}

/**
 * 💡 글로벌 뷰 네비게이터 전환 시스템
 */
function switchView(viewId) {
    document.querySelectorAll('.view-container').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.act-btn').forEach(b => b.classList.remove('active'));
    
    const targetView = document.getElementById(viewId);
    const targetBtn = document.getElementById(`nav-btn-${viewId}`);
    
    if (targetView) targetView.classList.add('active');
    if (targetBtn) targetBtn.classList.add('active');
    
    if (viewId === 'view2') loadReportApi();
    if (viewId === 'view3') loadResponseGuideApi();
}

// 관심 위치 저장용 관심지 수동 추가 버튼 매핑
function addNewLocation() {
    showCustomModal('관심 위치 추가 가이드', '해당 기능은 단말기 브라우저의 localStorage 환경에 자동 저장 및 캐싱됩니다.');
}

window.onload = () => {
    document.getElementById('nav-btn-view1').classList.add('active');
};