/**
 * 💡 전역 코어 데이터 모델 스토어 (주소 식별 시뮬레이션 고도화 및 침수 이력 데이터 통합)
 */
const appDatabase = {
    selectedAddress: '서울 관악구 신림동 1234-5',
    locations: [
        { id: 1, title: '우리 집', address: '관악구 신림동 1234-5', score: 72, grade: '고위험', color: '#ef4444' },
        { id: 2, title: '부모님 댁', address: '구로구 구로동 567-8', score: 38, grade: '주의', color: '#f59e0b' }
    ],
    // 검색 텍스트 유형별 결과 상태 구조 정의 (주소 기반 스코어링 시스템 엔진용)
    addressPatterns: {
        '신림': {
            totalScore: 72, grade: '고위험', color: '#ef4444', deg: 85,
            summary: '"반지하 구조와 저지대 특성이 결합돼 50mm 강우 시 침수 발생 가능성이 매우 높습니다."',
            contributions: [ {n:'반지하 구조', p:40, c:'#ef4444'}, {n:'저지대 위치', p:30, c:'#f59e0b'}, {n:'배수 밀도', p:20, c:'#3b82f6'}, {n:'침수 이력', p:10, c:'#10b981'} ],
            factors: [
                { title: '반지하 구조', score: 95, grade: '매우 높음', color: '#ef4444', desc: '지면 아래 주거공간으로 우수 유입 위험이 극히 높습니다. 침수 시 탈출 경로가 제한됩니다.' },
                { title: '저지대 위치', score: 78, grade: '높음', color: '#f59e0b', desc: '해발 4.2m, 주변 평균보다 3.1m 낮아 강우 집중 시 우수가 이 지점으로 모입니다.' },
                { title: '배수 밀도', score: 62, grade: '보통', color: '#3b82f6', desc: '반경 500m 내 하수관 밀도 0.8km/km². 집중호우 시 처리 용량 초과 우려가 있습니다.' },
                { title: '침수 이력 (추가 항목)', score: 88, grade: '위험', color: '#ef4444', desc: '과거 2022년 국지성 집중호우 시 인근 지역 도심형 하천 범람 및 침수 피해가 기록되어 있습니다.' }
            ]
        },
        '구로': {
            totalScore: 38, grade: '주의', color: '#f59e0b', deg: 25,
            summary: '"지형적 요인은 안전하나 관거 시설 노후화로 인해 국지성 호우 시 역류 주의가 필요합니다."',
            contributions: [ {n:'반지하 구조', p:10, c:'#ef4444'}, {n:'저지대 위치', p:20, c:'#f59e0b'}, {n:'배수 밀도', p:50, c:'#3b82f6'}, {n:'침수 이력', p:20, c:'#10b981'} ],
            factors: [
                { title: '반지하 구조', score: 20, grade: '낮음', color: '#10b981', desc: '고지대 및 일반 지상층 구조 위주로 외부 유입 위험성이 현저히 낮습니다.' },
                { title: '저지대 위치', score: 45, grade: '보통', color: '#3b82f6', desc: '평탄한 지형이나 인근 배수 펌프장 가동 반경에 속해 배수 관리가 원활합니다.' },
                { title: '배수 밀도', score: 82, grade: '높음', color: '#f59e0b', desc: '노후 관거 비중이 높아 단시간 시간당 40mm 이상 낙수 시 국지 정체 가능성 존재.' },
                { title: '침수 이력 (추가 항목)', score: 30, grade: '안전', color: '#10b981', desc: '지난 10년간 대규모 가옥 유입 피해 이력은 관찰되지 않은 안정 지역입니다.' }
            ]
        },
        'default': {
            totalScore: 15, grade: '안전', color: '#10b981', deg: -35,
            summary: '"고지대 암반 지형에 속해 침수 가능성이 희박하며 배수 인프라 상태가 매우 양호합니다."',
            contributions: [ {n:'반지하 구조', p:5, c:'#ef4444'}, {n:'저지대 위치', p:5, c:'#f59e0b'}, {n:'배수 밀도', p:40, c:'#3b82f6'}, {n:'침수 이력', p:50, c:'#10b981'} ],
            factors: [
                { title: '반지하 구조', score: 5, grade: '안전', color: '#34d399', desc: '해당 위치는 지상 구조물만 확인됩니다.' },
                { title: '저지대 위치', score: 12, grade: '안전', color: '#34d399', desc: '경사면 상단부 지형.' },
                { title: '배수 밀도', score: 25, grade: '양호', color: '#10b981', desc: '신설 빗물 저류조 인근.' },
                { title: '침수 이력 (추가 항목)', score: 5, grade: '무', color: '#34d399', desc: '침수 통계 이력 없음.' }
            ]
        }
    }
};

let currentMapZoom = 1.0;

/**
 * 💡 [AI 엔진 고도화] 입력 주소별 키워드 매칭 스코어 결정 로직
 */
function getActiveReportDataset() {
    const addr = appDatabase.selectedAddress;
    if (addr.includes('신림')) return appDatabase.addressPatterns['신림'];
    if (addr.includes('구로')) return appDatabase.addressPatterns['구로'];
    return appDatabase.addressPatterns['default'];
}

async function loadLocationsApi() {
    renderLocations(appDatabase.locations);
}

/**
 * 💡 [디자인 보정 및 침수 이력 주입] 실시간 동적 바인딩 함수
 */
async function loadReportApi() {
    const data = getActiveReportDataset();
    
    document.getElementById('api-report-addr').innerText = appDatabase.selectedAddress;
    document.getElementById('api-report-score').innerText = data.totalScore;
    
    const gradeEl = document.getElementById('api-report-grade');
    gradeEl.innerText = data.grade;
    gradeEl.style.color = data.color;

    document.getElementById('api-report-summary').innerText = data.summary;
    
    // 🎨 [변형 버그 패치] 업로드 사진에 명시된 반원 궤적 회전각 계산식 대입
    const gaugeBar = document.getElementById('api-gauge-bar');
    gaugeBar.style.borderColor = data.color;
    gaugeBar.style.borderLeftColor = 'transparent';
    gaugeBar.style.borderBottomColor = 'transparent';
    gaugeBar.style.transform = `rotate(${data.deg}deg)`;

    // 🏷️ 위험 지표 등급 가시성 액티브 보정
    document.querySelectorAll('.status-tag').forEach(tag => {
        tag.classList.remove('active', 'active-danger');
        tag.style.background = '#2d3748';
    });
    
    let activeTagId = 'tag-safe';
    if(data.grade === '고위험') activeTagId = 'tag-danger';
    if(data.grade === '주의') activeTagId = 'tag-watch';
    if(data.grade === '안전') activeTagId = 'tag-safe';
    
    const targetTag = document.getElementById(activeTagId);
    targetTag.classList.add('active');
    targetTag.style.background = data.color;

    renderContributions(data.contributions);
    renderFactors(data.factors);
}

function renderLocations(data) {
    const el = document.getElementById('api-location-list');
    el.innerHTML = data.map(item => `
        <div class="location-item" onclick="syncAndGo('${item.address}')">
            <div>
                <div class="loc-title">${item.title}</div>
                <div class="loc-sub">${item.address}</div>
            </div>
            <div class="loc-score-box">
                <div class="loc-score" style="color:${item.color}">${item.score}</div>
                <div class="loc-grade" style="color:${item.color}">${item.grade}</div>
            </div>
        </div>
    `).join('');
}

function syncAndGo(targetAddr) {
    appDatabase.selectedAddress = targetAddr;
    switchView('view2');
}

function renderContributions(data) {
    const el = document.getElementById('api-contrib-bar');
    el.innerHTML = data.map(c => `
        <div class="contrib-seg" style="width:${c.percentage}%; background:${c.color};">${c.percentage}%</div>
    `).join('');
}

function renderFactors(data) {
    const el = document.getElementById('api-factor-list');
    el.innerHTML = data.map(f => `
        <div class="factor-card">
            <div class="factor-header">
                <div class="factor-title">${f.title}</div>
                <div style="display:flex; align-items:center; gap:8px;">
                    <span style="font-size:16px; font-weight:bold; color:${f.color}">${f.score}</span>
                    <span class="factor-badge" style="background:${f.color}">${f.grade}</span>
                </div>
            </div>
            <div class="factor-bar-bg">
                <div class="factor-bar-fill" style="width:${f.score}%; background:${f.color}"></div>
            </div>
            <div class="factor-desc">${f.desc}</div>
        </div>
    `).join('');
}

function switchView(viewId) {
    document.querySelectorAll('.view-container').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.act-btn').forEach(b => b.classList.remove('active'));
    
    document.getElementById(viewId).classList.add('active');
    document.getElementById(`nav-btn-${viewId}`).classList.add('active');
    
    if (viewId === 'view2') loadReportApi();
    if (viewId === 'view3') {
        const currentData = getActiveReportDataset();
        document.getElementById('api-recalc-score').innerText = Math.max(15, currentData.totalScore - 15);
        document.getElementById('api-recalc-grade').innerText = currentData.grade;
    }
}

/**
 * 💡 [AI 주소 탐지 엔진] 검색바 입력 내용 기반 실시간 측정 연동 핸들러
 */
function handleSearch() {
    const val = document.getElementById('map-search-input').value;
    appDatabase.selectedAddress = val;
    
    const matched = getActiveReportDataset();
    const markerTxt = document.getElementById('map-marker-txt');
    markerTxt.innerHTML = `검색 위치 <span style="color:#93c5fd;">· ${matched.totalScore}점</span>`;
    
    alert(`[AI 지형 분석 스코어링 완료]\n입력 지역: ${val}\n산출 등급: ${matched.grade} (${matched.totalScore}점)\n하단 '위험 리포트' 탭 클릭 시 정밀 차트가 자동 동기화됩니다.`);
}

function addNewLocation() {
    const name = prompt("새로운 관심 위치 별칭을 입력하세요:");
    if(!name) return;
    const addr = prompt("상세 주소를 입력하세요 (예: 구로동, 신림동, 삼선동):", "구로구 구로동");
    if(!addr) return;
    
    appDatabase.selectedAddress = addr;
    const info = getActiveReportDataset();
    
    const newLoc = {
        id: Date.now(),
        title: name,
        address: addr,
        score: info.totalScore,
        grade: info.grade,
        color: info.color
    };
    appDatabase.locations.push(newLoc);
    renderLocations(appDatabase.locations);
}

function zoomMap(dir) {
    currentMapZoom += dir * 0.15;
    document.getElementById('user-house-marker').style.transform = `translate(-50%, -50%) scale(${currentMapZoom})`;
}

function resetMapLocation() {
    currentMapZoom = 1.0;
    document.getElementById('user-house-marker').style.transform = `translate(-50%, -50%) scale(1)`;
}

function updateRainScenario(val) {
    document.getElementById('slider-val-display').innerText = val + ' mm/h';
    document.getElementById('api-recalc-label').innerText = val + 'mm/h';
    
    const matched = getActiveReportDataset();
    let baseMultiplier = matched.totalScore > 50 ? 0.75 : 0.4;
    let simulatedScore = Math.min(99, 20 + Math.floor(val * baseMultiplier));
    
    document.getElementById('api-recalc-score').innerText = simulatedScore;
    
    const gradeLabel = document.getElementById('api-recalc-grade');
    if(simulatedScore >= 70) gradeLabel.innerText = '고위험';
    else if(simulatedScore >= 40) gradeLabel.innerText = '경고';
    else gradeLabel.innerText = '주의';

    document.querySelectorAll('.chart-bar').forEach((b, idx) => {
        if(idx <= Math.floor(val / 25)) b.classList.add('fill');
        else b.classList.remove('fill');
    });
}

function setSlider(val) {
    document.getElementById('rain-slider').value = val;
    document.querySelectorAll('.btn-seg').forEach(b => b.classList.remove('active'));
    document.getElementById(`seg-${val}`).classList.add('active');
    updateRainScenario(val);
}

function apiTrigger(actionName) {
    alert(`[시스템 외부 브릿지 연동]\n호출 대상 명세: ${actionName}`);
}

window.onload = () => {
    loadLocationsApi();
    document.getElementById('nav-btn-view1').classList.add('active');
};