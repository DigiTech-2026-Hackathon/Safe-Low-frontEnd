#include <stdio.h>
#include <windows.h>
#include <conio.h>
#include <time.h>

// 색상 정의
enum {
    BLACK,
    D_BLUE,
    D_GREEN,
    D_SKYBLUE,
    D_RED,
    D_VIOLET,
    D_YELLOW,
    GRAY,
    D_GRAY,
    BLUE,
    GREEN,
    SKYBLUE,
    RED,
    VIOLET,
    YELLOW,
    WHITE,
};

// 함수 선언
void gotoxy(int x, int y);
void setColor(int color);
void init();
void title();
void drawFrames();
void drawStatus(int stage, int gameTime, int mental, int progress, int energyDrink,
    int v_phone, int v_mon1, int v_mon2, int phone_gauge,
    int m1_pos, int m1_obs_lane, int m1_obs_y, int m1_dodge_count,
    int mon2_hp, int stretch_cooldown);
void ingame();
void gameOver(int finalTime, int progress);
void cursorOff();
void cursorOn();

int main() {
    init(); // 게임 초기화
    title(); // 타이틀 화면
    ingame(); // 인게임 진행

    setColor(WHITE);
    return 0;
}

// 콘솔 제어 함수 구현
void gotoxy(int x, int y) {
    COORD pos = { x, y };
    SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), pos);
}

void setColor(int color) {
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);
}

void cursorOff() {
    CONSOLE_CURSOR_INFO Information;
    Information.dwSize = 1;
    Information.bVisible = FALSE;
    SetConsoleCursorInfo(GetStdHandle(STD_OUTPUT_HANDLE), &Information);
}

void cursorOn() {
    CONSOLE_CURSOR_INFO Information;
    Information.dwSize = 1;
    Information.bVisible = TRUE;
    SetConsoleCursorInfo(GetStdHandle(STD_OUTPUT_HANDLE), &Information);
}

void init() {
    srand((unsigned int)time(NULL));
    system("title Text Based Game - reels (Advanced Edition)");
    system("mode con:cols=160 lines=45");
    cursorOff();
}

// 타이틀 화면
void title() {
    system("cls");

    setColor(RED);
    gotoxy(63, 1); printf("RRRRR EEEEE EEEEE L SSSSS");
    gotoxy(63, 2); printf("R R E E L S");
    gotoxy(63, 3); printf("RRRRR EEEE EEEE L SSS");
    gotoxy(63, 4); printf("R R E E L S");
    gotoxy(63, 5); printf("R R EEEEE EEEEE LLLLL SSSSS");

    drawFrames();

    setColor(BLUE);
    gotoxy(42, 27); printf("###### ###### ####### ##### ##### ### # # # #\n");
    gotoxy(42, 28); printf("# # # # # # # # # ## # # # \n");
    gotoxy(42, 29); printf("###### ###### ##### ##### ##### # # # # # # # \n");
    gotoxy(42, 30); printf("# # # # # # ####### # # # # \n");
    gotoxy(42, 31); printf("# # # ####### ##### ##### # # # ## # \n");

    setColor(YELLOW);
    gotoxy(58, 35); printf("[ 아무 키나 누르면 한층 고도화된 과제가 시작됩니다! ]");

    _getch();
    system("cls");
}

// UI 프레임 드로잉 함수
void drawFrames() {
    int i;

    // 1. 왼쪽 보조 모니터 (모니터 1) - x=4, 가로 54칸
    setColor(D_GRAY);
    gotoxy(4, 6); printf(" ____________________________________________________ ");
    for (i = 7; i <= 22; i++) {
        gotoxy(4, i); printf("| |");
    }
    gotoxy(4, 23); printf("|____________________________________________________|");
    gotoxy(23, 24); printf("|||||||||||||||||");
    gotoxy(18, 25); printf("===========================");

    // 2. 메인 모니터 (모니터 2) - x=62, 가로 54칸
    setColor(SKYBLUE);
    gotoxy(62, 6); printf(" ____________________________________________________ ");
    for (i = 7; i <= 22; i++) {
        gotoxy(62, i); printf("| |");
    }
    gotoxy(62, 23); printf("|____________________________________________________|");
    gotoxy(81, 24); printf("|||||||||||||||||");
    gotoxy(76, 25); printf("===========================");

    // 3. 우측 스마트폰 - x=120, 가로 34칸
    setColor(GREEN);
    gotoxy(120, 6); printf(" __________________________________ ");
    gotoxy(120, 7); printf("| ° |");
    for (i = 8; i <= 22; i++) {
        gotoxy(120, i); printf("| |");
    }
    gotoxy(120, 23); printf("|__________________________________|");
}

// 전체 대시보드 상태창 렌더링 함수
void drawStatus(int stage, int gameTime, int mental, int progress, int energyDrink,
    int v_phone, int v_mon1, int v_mon2, int phone_gauge,
    int m1_pos, int m1_obs_lane, int m1_obs_y, int m1_dodge_count,
    int mon2_hp, int stretch_cooldown) {
    int i;
    int obs_x;
    int ply_x;

    // [1] 스마트폰 화면 - 꾹 누르기 기믹
    if (v_phone) {
        setColor(RED);
        gotoxy(123, 10); printf("[🚨 SHORTS HOLD!]");
        setColor(YELLOW);
        gotoxy(122, 12); printf(" 릴스 알고리즘 유혹 발동!");
        gotoxy(122, 13); printf(" [1]번 키를 계속 유지하여");
        gotoxy(122, 14); printf(" 게이지를 100%% 채우세요!");
        setColor(WHITE);
        gotoxy(122, 17); printf("차단 게이지: [");
        for (i = 0; i < 10; i++) {
            if (phone_gauge / 10 > i) printf("■");
            else printf("░");
        }
        printf("] %d%%", phone_gauge);
    }
    else {
        setColor(GRAY);
        gotoxy(129, 13); printf("[스마트폰 인강]");
        gotoxy(124, 15); printf("화면이 평화롭게 꺼져있습니다.");
    }

    // [2] 보조 모니터 1 화면 - 장애물 피하기 미니게임 기믹
    if (stage >= 2) {
        if (v_mon1) {
            setColor(RED);
            gotoxy(6, 7); printf("🎮 악성코드 차단 미니게임 (장애물 피하기!)");
            setColor(YELLOW);
            gotoxy(6, 8); printf(" 조작: [A] 왼쪽으로 이동 | [D] 오른쪽으로 이동");
            gotoxy(6, 9); printf(" 목표: 낙하하는 바이러스를 3번 피하세요! (%d / 3)", m1_dodge_count);

            // 오브젝트 렌더링 위치 연산 (라인 0, 1, 2 에 매칭되는 X 좌표)
            obs_x = (m1_obs_lane == 0) ? 14 : ((m1_obs_lane == 1) ? 30 : 46);
            ply_x = (m1_pos == 0) ? 14 : ((m1_pos == 1) ? 30 : 46);

            // 트랙 가이드라인 표현
            setColor(D_GRAY);
            for (i = 11; i <= 20; i++) {
                gotoxy(14, i); printf("|");
                gotoxy(30, i); printf("|");
                gotoxy(46, i); printf("|");
            }

            // 낙하산 장애물 렌더링
            setColor(RED);
            gotoxy(obs_x - 2, m1_obs_y); printf("[💣]");

            // 플레이어 실시간 렌더링
            setColor(GREEN);
            gotoxy(ply_x - 3, 21); printf("└[▲]┘");
        }
        else {
            setColor(GREEN);
            gotoxy(14, 12); printf("[프로그래밍 과제 참고용 교재 PDF]");
            gotoxy(8, 14); printf("- 개념 정리: 조건문, 반복문, C언어 구조체 제어");
            gotoxy(8, 15); printf("- 🧘 스트레칭([R]): 7초마다 활성화, 정신력 +7 보너스");
        }
    }
    else {
        setColor(D_GRAY);
        gotoxy(22, 13); printf("[모니터 1 전원 꺼짐]");
        gotoxy(13, 15); printf("(2단계 스테이지 진입 시 전원이 켜집니다)");
    }

    // [3] 메인 모니터 2 화면 - 광고 팝업창 연타 차단
    if (stage >= 3 && v_mon2) {
        setColor(RED);
        gotoxy(64, 11); printf("🚨 [경고] 악성 팝업 광고창 대폭발!! [X] 🚨");
        setColor(YELLOW);
        gotoxy(64, 13); printf(" 광고: 테무 99%% 파격 세일! 지금 당장 클릭!");
        gotoxy(64, 14); printf(" 광고: 코딩 없이 해커가 되는 비법 대공개!");
        setColor(WHITE);
        gotoxy(64, 17); printf("🔥 X버튼 조준 클릭: [3]번 키 정밀 연타!!");
        setColor(D_RED);
        gotoxy(64, 19); printf("광고창 고정 나사: ");
        setColor(RED);
        for (i = 0; i < mon2_hp; i++) printf("◆");
        for (i = mon2_hp; i < 6; i++) printf("◇");
    }
    else {
        setColor(WHITE);
        gotoxy(80, 9); printf("Visual Studio 2026");
        gotoxy(64, 10); printf("----------------------------------------------------");
        gotoxy(66, 12); printf("#include <stdio.h> // 과제 타이핑 진행률: %d.%d%%", progress / 10, progress % 10);
        gotoxy(66, 13); printf("int main() {");
        gotoxy(70, 14); printf("printf(\"서울디지텍고 프로그래밍 과제 제출물\\n\");");
        if (progress >= 1000) {
            setColor(GREEN);
            gotoxy(70, 16); printf("return 0; // 코딩 완벽 완료! 남은 시간을 버티세요!");
        }
        else {
            setColor(YELLOW);
            gotoxy(70, 16); printf("/* ⌨️ [C] 키를 타이핑하여 코드를 완성해 가세요! */");
        }
    }

    // [하단 와이드 메인 상태창 UI]
    setColor(WHITE);
    gotoxy(4, 26); printf("======================================================================================================================================================");
    gotoxy(6, 27); printf(" 📊 현재 스테이지 : %d 단계 %s", stage < 4 ? stage : 3, stage == 4 ? "🔥 [최종 무한 기록 경쟁 버티기 모드!]" : "");
    gotoxy(6, 28); printf(" 🕒 과제 수행 시간 : %3d 분 / 180 분 (실제 시간 정확히 3분 타이머 진행)", gameTime);
    gotoxy(6, 29); printf(" 🧠 나의 정신력 : [%3d / 100] %s", mental, mental < 30 ? "⚠️ (위험! 눈이 감기려고 합니다!)" : "👍 안정적");
    gotoxy(6, 30); printf(" 💾 과제 구현율 : [%3d.%d%%] %s", progress / 10, progress % 10, progress >= 1000 ? "✅ 타이핑 완료!" : "⏳ 소스코드 작성 중...");
    gotoxy(6, 31); printf(" 🥤 보유 인벤토리 : 에너지 드링크 [%d개] (복용: [H]키)", energyDrink);

    // 스트레칭 실시간 쿨타임 조건부 출력 기능
    gotoxy(6, 32); printf(" 🧘 허리 스트레칭 : [R] 키 입력 (정신력 +7 회복) -> ⏳ 현재 상태: ");
    if (stretch_cooldown > 0) {
        setColor(RED);
        printf("[%d.%d초 쿨다운 대기 중]", stretch_cooldown / 10, stretch_cooldown % 10);
    }
    else {
        setColor(GREEN);
        printf("★ 사용 가능 (READY) ★");
    }

    setColor(WHITE);
    gotoxy(4, 34); printf("------------------------------------------------------------------------------------------------------------------------------------------------------");
    gotoxy(6, 35); printf(" ⌨️ 실시간 인터랙티브 조작 가이드:");
    gotoxy(8, 36); printf(" • [C] 과제 코딩 타이핑 (방해 요소를 모두 제거해야 효율이 극대화됩니다)");
    gotoxy(8, 37); printf(" • [1] 스마트폰 릴스 차단 (게이지가 참을 때까지 꾹 유지하듯 지속 입력!)");
    gotoxy(8, 38); printf(" • [A] / [D] 보조모니터 1 악성코드 폭탄 좌우 회피 기믹 제어");
    gotoxy(8, 39); printf(" • [3] 메인모니터 광고창 X버튼 마우스 연타 분쇄");
    gotoxy(8, 40); printf(" • [H] 에너지 드링크 복용 | [R] 눈 피로 풀기 및 스트레칭 (7초 쿨타임, 정신력 +7)");
    gotoxy(8, 41); printf(" • [Q] 과제 포기 탈주 (게임 종료)");
    gotoxy(4, 43); printf("======================================================================================================================================================");
}

// 인게임 논블로킹 엔진 구동 루프
void ingame() {
    // C 표준 준수를 위한 변수 최상단 배치
    int mental = 100;
    int progress_raw = 0;
    int gameTime = 0;
    int energyDrink = 3;
    int stage = 1;

    int virus_phone = 0;
    int virus_mon1 = 0;
    int virus_mon2 = 0;

    int mon2_hp = 0;

    // [신규] 스마트폰 꾹 누르기용 데이터
    int phone_gauge = 0;

    // [신규] 장애물 피하기용 데이터 
    int m1_pos = 1; // 플레이어 현재 라인 (0:좌, 1:중, 2:우)
    int m1_obs_lane = 0; // 장애물 스폰 라인
    int m1_obs_y = 11; // 장애물 Y 축 시작 좌표
    int m1_dodge_count = 0;// 성공적인 회피 카운트
    int m1_tick = 0; // 장애물 하강 속도 제어 타이머

    // [신규] 스트레칭 쿨타임 데이터 (100ms 단위이므로 7초 = 70)
    int stretch_cooldown = 0;

    int loopCounter = 0;
    int need_refresh = 0;
    int key;
    int randVal;
    int drain;
    int hitCount;
    int i;
    int ch;

    // 시작 연출
    setColor(YELLOW); gotoxy(10, 5); printf("================================");
    setColor(WHITE); gotoxy(10, 6); printf(" 새로운 시스템으로 과제를 시작합니다.");
    setColor(YELLOW); gotoxy(10, 7); printf("================================");
    Sleep(1000);
    system("cls");

    drawFrames();
    drawStatus(stage, gameTime, mental, progress_raw, energyDrink, virus_phone, virus_mon1, virus_mon2, phone_gauge, m1_pos, m1_obs_lane, m1_obs_y, m1_dodge_count, mon2_hp, stretch_cooldown);

    while (1) {
        need_refresh = 0;

        // [1] 실시간 고속 키보드 입력 탐지
        if (_kbhit()) {
            key = _getch();

            if (key == 'q' || key == 'Q') {
                break;
            }

            // 과제 코딩 프로세스
            if (key == 'c' || key == 'C') {
                if (!virus_phone && !virus_mon1 && !virus_mon2) {
                    progress_raw += (rand() % 2 + 2);
                }
                else {
                    progress_raw += (rand() % 2);
                }
                if (progress_raw > 1000) progress_raw = 1000;
                need_refresh = 1;
            }

            // [개선] 스트레칭 기능 - 7초 제한 조건 부여
            if (key == 'r' || key == 'R') {
                if (stretch_cooldown == 0) {
                    mental += 7; // 정신력 7 증가
                    if (mental > 100) mental = 100;
                    stretch_cooldown = 70; // 70틱 = 7초 쿨타임 지정
                }
                need_refresh = 1;
            }

            // 드링크 복용
            if (key == 'h' || key == 'H') {
                if (energyDrink > 0) {
                    energyDrink--;
                    mental += 30;
                    if (mental > 100) mental = 100;
                }
                need_refresh = 1;
            }

            // 꾹 누르기 기믹 입력 처리
            if (key == '1') {
                if (virus_phone) {
                    phone_gauge += 12; // 누를 때마다 상승
                }
                need_refresh = 1;
            }

            // 장애물 피하기 좌우 조작 처리
            if (key == 'a' || key == 'A') {
                if (virus_mon1 && m1_pos > 0) {
                    m1_pos--;
                }
                need_refresh = 1;
            }
            if (key == 'd' || key == 'D') {
                if (virus_mon1 && m1_pos < 2) {
                    m1_pos++;
                }
                need_refresh = 1;
            }

            // 모니터 2 팝업창 연타 분쇄
            if (key == '3') {
                if (virus_mon2) {
                    mon2_hp--;
                    if (mon2_hp <= 0) {
                        virus_mon2 = 0;
                        mental += 5;
                        if (mental > 100) mental = 100;
                    }
                }
                need_refresh = 1;
            }
        }

        // [2] 꾹 누르기 가상 유지 자동 게이지 감쇠 연산
        if (virus_phone) {
            phone_gauge -= 2; // 가만히 있으면 매 프레임마다 2%씩 흘러내림
            if (phone_gauge < 0) phone_gauge = 0;

            if (phone_gauge >= 100) {
                virus_phone = 0;
                phone_gauge = 0;
                mental += 6;
                if (mental > 100) mental = 100;
            }
            need_refresh = 1;
        }

        // [3] 장애물 낙하 흐름 제어 스레드 시뮬레이션 (300ms마다 낙하)
        if (virus_mon1) {
            m1_tick++;
            if (m1_tick >= 3) {
                m1_tick = 0;
                m1_obs_y++;

                // 바닥선(방어선) 도달 시점 연산
                if (m1_obs_y == 21) {
                    if (m1_obs_lane == m1_pos) {
                        // 피하지 못하고 충돌했을 때!
                        mental -= 14;
                        if (mental < 0) mental = 0;
                    }
                    else {
                        // 안전하게 회피 성공!
                        m1_dodge_count++;
                    }

                    // 장애물 초기화 및 랜덤 라인 재배치
                    m1_obs_y = 11;
                    m1_obs_lane = rand() % 3;
                }

                // 3번 회피 달성 시 클리어
                if (m1_dodge_count >= 3) {
                    virus_mon1 = 0;
                    m1_dodge_count = 0;
                    mental += 10;
                    if (mental > 100) mental = 100;
                }
                need_refresh = 1;
            }
        }

        // [4] 스트레칭 실시간 쿨타임 타이머 차감 (100ms 단위)
        if (stretch_cooldown > 0) {
            stretch_cooldown--;
            need_refresh = 1;
        }

        // [5] 1초 주기의 핵심 메인 데이터 연산 (100ms * 10)
        loopCounter++;
        if (loopCounter >= 10) {
            loopCounter = 0;
            gameTime += 1; // 실제 시간 1초당 게임 시계 1분 경과 (총 180초 = 3분 매칭)

            if (gameTime < 60) stage = 1;
            else if (gameTime < 120) stage = 2;
            else if (gameTime < 180) stage = 3;
            else stage = 4;

            // 확률적 디버프 바이러스 공격 개시
            randVal = rand() % 100;
            if (randVal < 25) {
                if (stage >= 1 && !virus_phone) {
                    virus_phone = 1;
                    phone_gauge = 20; // 20% 보정 시작값
                }
                if (stage >= 2 && !virus_mon1 && (rand() % 2 == 0)) {
                    virus_mon1 = 1;
                    m1_pos = 1;
                    m1_obs_lane = rand() % 3;
                    m1_obs_y = 11;
                    m1_dodge_count = 0;
                }
                if (stage >= 3 && !virus_mon2 && (rand() % 2 == 0)) {
                    virus_mon2 = 1;
                    mon2_hp = 6;
                }
            }

            // 실시간 상태에 따른 패널티 다중 중첩 연산
            drain = 1;
            if (virus_phone) drain += 2;
            if (virus_mon1) drain += 3;
            if (virus_mon2) drain += 3;

            mental -= drain;
            if (mental < 0) mental = 0;

            // 정신력 소진에 따른 최후의 기상 연타 챌린지
            if (mental <= 0) {
                system("cls");
                setColor(RED);
                gotoxy(55, 14); printf("==================================================");
                gotoxy(55, 15); printf(" !!! 눈 이 자 꾸 감 긴 다 !!! ");
                gotoxy(55, 16); printf("==================================================");
                setColor(WHITE);
                gotoxy(45, 18); printf("몰려오는 졸음을 강제로 깨우기 위해 [SPACEBAR]를 정신없이 연타하세요!");
                setColor(YELLOW);
                gotoxy(60, 20); printf("🔥 목표: 제한시간 3초 내에 15회 연타 입력");

                hitCount = 0;
                for (i = 0; i < 30; i++) {
                    if (_kbhit()) {
                        ch = _getch();
                        if (ch == ' ') {
                            hitCount++;
                            gotoxy(70, 22); printf("현재 기상 게이지: %d / 15", hitCount);
                        }
                    }
                    Sleep(100);
                }

                if (hitCount >= 15) {
                    mental = 30;
                    system("cls");
                    setColor(GREEN);
                    gotoxy(62, 18); printf("🔋 가까스로 정신을 차리고 다시 키보드를 잡았습니다!");
                    Sleep(1200);
                }
                else {
                    break; // 패배
                }
            }
            need_refresh = 1;
        }

        // 불필요한 깜빡임을 억제하기 위해 변화 플래그가 있을 때만 청소 후 렌더링
        if (need_refresh) {
            system("cls");
            drawFrames();
            drawStatus(stage, gameTime, mental, progress_raw, energyDrink, virus_phone, virus_mon1, virus_mon2, phone_gauge, m1_pos, m1_obs_lane, m1_obs_y, m1_dodge_count, mon2_hp, stretch_cooldown);
        }

        Sleep(100); // 쾌적한 입력 감지 폴링 인터벌 속도 보장
    }

    gameOver(gameTime, progress_raw / 10);
}

// 최종 결과 엔딩 화면 출력 함수
void gameOver(int finalTime, int progress) {
    system("cls");

    if (finalTime >= 180 && progress >= 100) {
        setColor(GREEN);
        gotoxy(55, 12); printf("==================================================");
        gotoxy(55, 13); printf(" 🎉 [SUCCESS] 과제를 마침내 끝냈다! 🎉 ");
        gotoxy(55, 14); printf("==================================================");
        setColor(WHITE);
        gotoxy(55, 16); printf(" 당신은 꾹 누르기와 장애물 회피 멀티태스킹 천재군요!");
        gotoxy(55, 17); printf(" 완벽한 소스코드를 구축하여 교수님께 A+ 메일을 전송했습니다.");
        setColor(YELLOW);
        gotoxy(55, 19); printf(" 🏆 총 누적 생존 시간: %d분 완벽 방어 성공!", finalTime);
    }
    else {
        setColor(RED);
        gotoxy(55, 12); printf("==================================================");
        gotoxy(55, 13); printf(" 😭 [FAILED] 과제를 완료하지 못했다... ");
        gotoxy(55, 14); printf("==================================================");
        setColor(WHITE);
        gotoxy(55, 16); printf(" 쏟아지는 악성 바이러스 폭탄과 유혹의 릴스를 버티지 못했습니다.");
        gotoxy(55, 17); printf(" 미완성 과제(제출도 %d%%)로 인해 시스템이 셧다운되었습니다.", progress);
        setColor(YELLOW);
        gotoxy(55, 19); printf(" 🕒 최종 버틴 기록: %d분 (목표 스펙: 180분 완료 및 100%% 마감)", finalTime);
    }

    setColor(GRAY);
    gotoxy(55, 24); printf("아무 키나 누르면 게임 창을 안전하게 종료합니다...");
    _getch();
}