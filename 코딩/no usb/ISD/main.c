#include <stdio.h>
#include <windows.h>
#include <conio.h>
#include <time.h>
#include <locale.h>

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
void ingame();
void gameOver(int finalTime, int progress);
void cursorOff();

// 커서 이동
void gotoxy(int x, int y) {
    COORD pos = { (SHORT)x, (SHORT)y };
    SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), pos);
}

// 색상 설정
void setColor(int color) {
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);
}

// 커서 숨기기
void cursorOff() {
    CONSOLE_CURSOR_INFO ci;
    ci.dwSize = 1;
    ci.bVisible = FALSE;
    SetConsoleCursorInfo(GetStdHandle(STD_OUTPUT_HANDLE), &ci);
}

// 초기 설정
void init() {
    setlocale(LC_ALL, "");
    srand((unsigned int)time(NULL));
    system("title Text Game");
    system("mode con:cols=120 lines=40");
    cursorOff();
}

// 타이틀
void title() {
    system("cls");

    setColor(YELLOW);
    gotoxy(40, 10);
    printf("=== 콘솔 과제 생존 게임 ===");

    setColor(WHITE);
    gotoxy(35, 15);
    printf("아무 키나 눌러 시작...");
    _getch();
}

// 프레임
void drawFrames() {
    int i;
    setColor(D_GRAY);

    for (i = 5; i < 30; i++) {
        gotoxy(5, i); printf("|");
        gotoxy(110, i); printf("|");
    }

    for (i = 5; i <= 110; i++) {
        gotoxy(i, 5); printf("-");
        gotoxy(i, 30); printf("-");
    }
}

// 게임
void ingame() {
    int mental = 100;
    int progress = 0;
    int timeCount = 0;
    int loop = 0;

    while (1) {
        // 입력 처리
        if (_kbhit()) {
            int key = _getch();

            if (key == 'q') break;

            if (key == 'c') {
                progress += 2;
                if (progress > 100) progress = 100;
            }

            if (key == 'r') {
                mental += 5;
                if (mental > 100) mental = 100;
            }
        }

        // 1초 단위 처리
        loop++;
        if (loop >= 10) {
            loop = 0;
            timeCount++;

            mental--;
            if (mental < 0) mental = 0;
        }

        // 화면 출력
        system("cls");
        drawFrames();

        setColor(GREEN);
        gotoxy(10, 8);
        printf("정신력: %d", mental);

        setColor(YELLOW);
        gotoxy(10, 10);
        printf("진행도: %d%%", progress);

        setColor(WHITE);
        gotoxy(10, 12);
        printf("시간: %d", timeCount);

        gotoxy(10, 15);
        printf("[C] 코딩 / [R] 회복 / [Q] 종료");

        // 게임 종료 조건
        if (mental <= 0) break;
        if (progress >= 100) break;

        Sleep(100);
    }

    gameOver(timeCount, progress);
}

// 게임 종료
void gameOver(int finalTime, int progress) {
    system("cls");

    if (progress >= 100) {
        setColor(GREEN);
        printf("과제 성공!\n");
    }
    else {
        setColor(RED);
        printf("실패...\n");
    }

    setColor(WHITE);
    printf("시간: %d\n", finalTime);
    printf("진행도: %d%%\n", progress);

    _getch();
}

// 메인
int main() {
    init();
    title();
    ingame();
    return 0;
}