#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
#Persistent
#Warn
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 3
CoordMode, ToolTip, Screen
DetectHiddenText, On
DetectHiddenWindows, On

;-- 변수 선언 ----------------------------------------------------------------------------------------------------
global varVer = "카카오톡 자동응답"
global varOnoff := 0
global varStatus1, varStatus2, varStatus3
global varWorking
global varAway
global varHome
global varNTF
global var5min
global varEdit

;=================================================================================================================================
;=================================================================================================================================
start:

IfNotExist, MAssistant.ini
{
	IniWrite, 반갑습니다(방긋) 앞서 문의주신 손님께 답변 중이니 잠시만 기다려주세요(방긋), MAssistant.ini, Sample,varWorking
	IniWrite, 반갑습니다(방긋) 지금은 부재중이라 상담에 응해드릴 수가 없어요. 제가 다시 연락드릴께요(눈물), MAssistant.ini, Sample,varAway
	IniWrite, 고객님(눈물) 상담가능한 시간은 오전 9시부터 오후 6시까지 입니다(눈물) 상담시간에 제가 연락드리겠습니다(눈물), MAssistant.ini, Sample,varHome
}

;-- 현재 상태 ----------------------------------------------------------------------------------------------------
Gui, Add, GroupBox, x12 y10 w90 h140 , 현재 상태

Gui, Add, Radio, x22 y30 w60 h20 gactionStatus vvarStatus1, 대화 중
Gui, Add, Radio, x22 y70 w70 h20 gactionStatus vvarStatus2, 부재중
Gui, Add, Radio, x22 y110 w70 h20 gactionStatus vvarStatus3, 로그아웃

IniRead, varStatus1		, MAssistant.ini, Status,varStatus1,1
IniRead, varStatus2		, MAssistant.ini, Status,varStatus2,0
IniRead, varStatus3		, MAssistant.ini, Status,varStatus3,0
GuiControl,,varStatus1, %varStatus1%
GuiControl,,varStatus2, %varStatus2%
GuiControl,,varStatus3, %varStatus3%

;-- 에디트 컨트롤 -------------------------------------------------------------------------------------------------
Gui, Add, GroupBox, x112 y10 w210 h140 , 현재 지정된 메시지
Gui, Add, Edit, x122 y30 w190 h110 vvarEdit

IniRead, varWorking		, MAssistant.ini, Sample,varWorking
IniRead, varAway		, MAssistant.ini, Sample,varAway
IniRead, varHome		, MAssistant.ini, Sample,varHome

Gui, Submit, NoHide
If varStatus1 = 1
	GuiControl,,varEdit, %varWorking%
else if varStatus2 = 1
	GuiControl,,varEdit, %varAway%
else if varStatus3 = 1
	GuiControl,,varEdit, %varHome%

;--추가 기능-------------------------------------------------------------------------------------------------------
Gui, Add, GroupBox, x12 y160 w310 h70, 추가 기능 ; group-box

Gui, Add, CheckBox, x22 y180 w290 h20 vvarNTF gactionNTF, 친구에게는 메시지를 전송하지 않습니다. ;varNTF ;~varNotToFriend
Gui, Add, CheckBox, x22 y200 w290 h20 vvar5min gaction5min, 5분 동안 입력이 없으면 자동으로 실행합니다. ;var5min

IniRead, varNTF			, MAssistant.ini, Option,varNTF,1
IniRead, var5min		, MAssistant.ini, Option,var5min,0
GuiControl,,varNTF, %varNTF%
GuiControl,,var5min, %var5min%

;--버튼 모음-------------------------------------------------------------------------------------------------------
Gui Font, cRed
GuiControl Font, status
Gui, Add, text, x332 y25 w80 h60 center hidden vstatus, 자동 응답 중
Gui, Add, Button, x332 y50 w80 h60 vonoff,On/Off
Gui, Add, Button, x332 y115 w80 h35 vmsgSave, 메시지 저장 ;actionChangeMsg
Gui, Add, Button, x332 y195 w80 h35 vquit, 종료`(&Q`) ;~ display a pop-up TBD
Gui, Show, x1 y1 w423 h240, 카카오톡 자동리

main:

Gui +lastfound
hWnd := WinExist()

DllCall( "RegisterShellHookWindow", UInt,hWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )

inactivity_limit=300	; measured in seconds
how_often_to_test=10	; measured in seconds
show_tooltip=1       ; 1=show, anything else means hide

inactivity_limit_ms:=inactivity_limit*1000
how_often_to_test_ms:=how_often_to_test*1000

IfNotExist, %A_ScriptDir%\customers.txt
			FileAppend, Mall Assistant v1.0 Customer Log`n,%A_ScriptDir%\customers.txt

settimer, check_active, %how_often_to_test_ms%

return
;=================================================================================================================================
;=================================================================================================================================
ButtonOn/Off:
Critical
Gui, Submit, NoHide
OnMessage(MsgNum, (varOnOff := !varOnOff) ? "ShellMessage" : "")
If varOnoff = 1
{
	If GetKeyState("Ctrl", "P") = 0
	{
		If CheckKakaoLogin()
			Intro()
	}
	If varOnoff = 1
	{
		GuiControl, show, status
		GuiControl, disable, varStatus1
		GuiControl, disable, varStatus2
		GuiControl, disable, varStatus3
		GuiControl, disable, varNTF
		GuiControl, disable, var5min
		GuiControl, disable, msgSave
		GuiControl, disable, about
		GuiControl, disable, varEdit
		TrayTip,자동 응답을 시작합니다^^,1
		SetTimer, RemoveTrayTip, 1000
	}
}
else
{
	Outro()
	GuiControl, hide, status
	GuiControl, enable, varStatus1
	GuiControl, enable, varStatus2
	GuiControl, enable, varStatus3
	GuiControl, enable, varNTF
	GuiControl, enable, var5min
	GuiControl, enable, msgSave
	GuiControl, enable, about
	GuiControl, enable, varEdit
}
return

check_active:
if A_TimeIdlePhysical > %inactivity_limit_ms%
{
	If varOnoff = 0
	{
		If var5min = 1
		{
			ControlClick, On/Off, 카카오톡자동리
		}
	}
}
return

Intro() ;3초 대기 후 시작
{
	GuiControl, disable, onoff
	Loop, 3
	{
	tempCnt := 3 - A_Index + 1
	TrayTip, %tempCnt%초 뒤 자동 응답을 시작합니다^^,1
	SetTimer, RemoveTrayTip, 900
	sleep, 970
	}
	GuiControl, enable, onoff
}

Outro()
{
	TrayTip,자동 응답을 종료합니다^^,1
	SetTimer, RemoveTrayTip, 1000
	SaveAll()
}

CheckKakaoLogin() ;카카오톡 로그인 상태 확인
{
	IfWinExist, 카카오톡
	{
		WinShow, 카카오톡
		WinActivate, 카카오톡
		ControlGet, varCKLcontrol, Visible,, Edit2, 카카오톡
		If varCKLcontrol{
			msgbox, 0x1040, 카카오톡에 로그인을 해 주세요 :)
			varOnoff := 0
			return 0
		}
	}
	else{
		varOnoff := 0
		msgbox, 0x1040, 카카오톡을 먼저 실행 해 주세요 :)
	return 0
	}
	return 1
}


ShellMessage( wParam,lParam ) ;푸시 알림 감지 및 채팅창 열기
{
	WinGetTitle, Title, ahk_id %lParam%
	If (( wParam = 32774 ) && ( Title = "카카오톡" ))
	{
		BlockInput, On
		Winwait, ahk_class EVA_Window_Dblclk,,0
		ControlClick, x1 y1, ahk_class EVA_Window_Dblclk
		sleep, 100
		If varNTF && DetermineFriend()
			return
		
		IfNotExist, %A_ScriptDir%\customers.txt
			FileAppend, Mall Assistant v1.0 Customer Log`n,%A_ScriptDir%\customers.txt

		WinGet, id, list, ahk_class #32770,,카카오톡
		Loop %id%
		{
			if %id%
			{
				
				this_id := id%A_Index%
				WinGetTitle, varCTitle, ahk_id %this_id%
			
				varWrite := 1
				;--------------중복 여부만을 검사---------------------------------
				Loop, read, %A_ScriptDir%\customers.txt
				{
					If varCTitle = %A_LoopReadLine%
						varWrite := 0
				}
				if varWrite
				{
					FileAppend, %varCTitle%`n, %A_ScriptDir%\customers.txt
					SendKaKaoMessage(varEdit,varCTitle)
				}
			}
		}
	}
	BlockInput, Off	
	return
}

DetermineFriend() ;친구여부 판단, 1 : 친구, 0 : 친구아님
{
	Winwait, ahk_class EVA_Window_Dblclk,,0
	ControlClick, x20 y20, ahk_class EVA_Window_Dblclk

	ControlGetPos, varDFnd,,,,EVA_Window1,ahk_class #32770
	If varDFnd
	{
		Send, {ESC}
		return 1
	}
	else
		return 0
}

; 사용예시 SendKakaoMessage("Message","Matthew Burrows")
SendKaKaoMessage(Word, Name) ;카톡으로 메시지 보내기
{
	Clipboard=%Word%
	clipWait
	IfWinExist, %Name%
	{
		PostMessage,0x302,1,0,RichEdit20W1,%Name%
		sleep, 120
		PostMessage,0x100,0x0D,0,RichEdit20W1,%Name%
	}
}

SaveAll() ;설정내용 저장
{
	Gui, Submit, nohide
	IniWrite, %varStatus1%, MAssistant.ini, Status,varStatus1
	IniWrite, %varStatus2%, MAssistant.ini, Status,varStatus2
	IniWrite, %varStatus3%, MAssistant.ini, Status,varStatus3
	If varStatus1 = 1
	IniWrite, %varEdit%, MAssistant.ini, Sample, varWorking
	Else if varStatus2 = 1
	IniWrite, %varEdit%, MAssistant.ini, Sample, varAway
	Else if varStatus3 = 1
	IniWrite, %varEdit%, MAssistant.ini, Sample, varHome
	IniWrite, %varNTF%, MAssistant.ini, Option,varNTF
	IniWrite, %var5min%, MAssistant.ini, Option,var5min
}

actionStatus:
Gui, Submit, NoHide
IniRead, varWorking		, MAssistant.ini, Sample,varWorking
IniRead, varAway		, MAssistant.ini, Sample,varAway
IniRead, varHome		, MAssistant.ini, Sample,varHome

If varStatus1 = 1
	GuiControl,,varEdit, %varWorking%
else if varStatus2 = 1
	GuiControl,,varEdit, %varAway%
else if varStatus3 = 1
	GuiControl,,varEdit, %varHome%
return

actionNTF:
action5min:
Gui, Submit, NoHide
return


actionOK:
Gui,2:Destroy
return

Button메시지저장:
SaveAll()
return

Button종료(Q):
GuiClose:
Outro()
SaveAll()
ExitApp

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

RemoveTrayTip:
SetTimer, RemoveTrayTip, Off
TrayTip
return