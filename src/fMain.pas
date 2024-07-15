unit fMain;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  uDMLogo,
  FMX.StdCtrls,
  FMX.TabControl,
  FMX.Controls.Presentation,
  Olf.FMX.AboutDialog,
  FMX.Menus,
  System.Actions,
  FMX.ActnList,
  FMX.Layouts,
  FMX.Media,
  uProjectVISP,
  FMX.Objects,
  FMX.ListBox,
  uSplitterWorker,
  Olf.FMX.SelectDirectory;

type
  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    OlfAboutDialog1: TOlfAboutDialog;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    lblStatus: TLabel;
    ActionList1: TActionList;
    mnuMacOS: TMenuItem;
    mnuFile: TMenuItem;
    mnuProject: TMenuItem;
    mnuTools: TMenuItem;
    mnuHelp: TMenuItem;
    mnuFileNew: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileClose: TMenuItem;
    mnuFileQuit: TMenuItem;
    mnuProjectOptions: TMenuItem;
    mnuToolsOptions: TMenuItem;
    mnuHelpAbout: TMenuItem;
    btnProjectOpen: TButton;
    btnProjectClose: TButton;
    btnProjectOptions: TButton;
    btnToolsOptions: TButton;
    btnQuit: TButton;
    btnAbout: TButton;
    actQuit: TAction;
    actProjectOpen: TAction;
    actProjectNew: TAction;
    actProjectSave: TAction;
    actProjectClose: TAction;
    actProjectOptions: TAction;
    actAbout: TAction;
    actOptions: TAction;
    MediaPlayer1: TMediaPlayer;
    odVISPProject: TOpenDialog;
    sdVISPProject: TSaveDialog;
    odVideoFile: TOpenDialog;
    btnProjectNew: TButton;
    lProject: TLayout;
    FlowLayout1: TFlowLayout;
    btnGotoStart: TButton;
    pGotoStart: TPath;
    btnPrevSeconde: TButton;
    pPrevSeconde: TPath;
    btnPrevFrame: TButton;
    pPrevFrame: TPath;
    btnPlayPause: TButton;
    pPlay: TPath;
    pPause: TPath;
    btnNextFrame: TButton;
    pNextFrame: TPath;
    btnNextSeconde: TButton;
    pNextSeconde: TPath;
    btnGotoEnd: TButton;
    pGotoEnd: TPath;
    MediaPlayerControl1: TMediaPlayerControl;
    lblSourceFile: TLabel;
    tbVideo: TTrackBar;
    CheckVideoPositionTimer: TTimer;
    tbVolume: TTrackBar;
    lblVolume: TLabel;
    lProjectRight: TLayout;
    lbVideoParts: TListBox;
    lblVideosParts: TLabel;
    FlowLayout2: TFlowLayout;
    btnAddMark: TButton;
    pAddMark: TPath;
    btnRemoveMark: TButton;
    pRemoveMark: TPath;
    ListBoxItem1: TListBoxItem;
    Layout1: TLayout;
    lblVol0: TLabel;
    lblVol100: TLabel;
    AniIndicator1: TAniIndicator;
    btnProjectExport: TButton;
    mnuProjectExport: TMenuItem;
    actProjectExport: TAction;
    GridPanelLayout1: TGridPanelLayout;
    lblWaitingListStatus: TLabel;
    procedure actQuitExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actProjectOpenExecute(Sender: TObject);
    procedure actProjectNewExecute(Sender: TObject);
    procedure actProjectSaveExecute(Sender: TObject);
    procedure actProjectCloseExecute(Sender: TObject);
    procedure actProjectOptionsExecute(Sender: TObject);
    procedure actOptionsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OlfAboutDialog1URLClick(const AURL: string);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnPlayPauseClick(Sender: TObject);
    procedure btnGotoStartClick(Sender: TObject);
    procedure btnGotoEndClick(Sender: TObject);
    procedure btnNextSecondeClick(Sender: TObject);
    procedure btnPrevSecondeClick(Sender: TObject);
    procedure btnPrevFrameClick(Sender: TObject);
    procedure btnNextFrameClick(Sender: TObject);
    procedure CheckVideoPositionTimerTimer(Sender: TObject);
    procedure tbVideoTracking(Sender: TObject);
    procedure tbVolumeTracking(Sender: TObject);
    procedure btnRemoveMarkClick(Sender: TObject);
    procedure btnAddMarkClick(Sender: TObject);
    procedure lbVideoPartsChangeCheck(Sender: TObject);
    procedure lbVideoPartsItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure actProjectExportExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FCurrentProject: TVISPProject;
    FVideoDuration: int64;
    FVideoDurationSecondes: double;
    procedure SetCurrentProject(const Value: TVISPProject);
    procedure SetCurrentTime(const Value: int64);
    function GetCurrentTime: int64;
    procedure UpdateTrackbarValue(const CurTime: int64);
    procedure SetVideoDuration(const Value: int64);
    procedure SetWaitingListCount(const Value: nativeint);
  protected
    FTrackingFromMediaPlayer: Boolean;
    FSplittingWorker: TSplittingWorker;
    property CurrentTime: int64 read GetCurrentTime write SetCurrentTime;
    property VideoDuration: int64 read FVideoDuration write SetVideoDuration;
    property VideoDurationSecondes: double read FVideoDurationSecondes;
    property WaitingListCount: nativeint write SetWaitingListCount;
    procedure AddLog(Const Text: string);
    procedure InitMainFormCaption;
    procedure InitAboutDialogDescriptionAndLicense;
    procedure InitMainMenuForMacOS;
    procedure SubscribeToProjectChangedMessage;
    procedure InitVideoParts;
    procedure AddMark(const ATime: int64);
  public
    property CurrentProject: TVISPProject read FCurrentProject
      write SetCurrentProject;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  System.Messaging,
  System.IOUtils,
  Olf.FMX.AboutDialogForm,
  u_urlOpen,
  fOptions,
  uConfig,
  fProjectOptions,
  uTools;

type
  TMarkItem = class(TListBoxItem)
  private
    FMark: TMark;
    procedure SetMark(const Value: TMark);
  protected
    procedure CheckboxChange(Sender: TObject);
  public
    property Mark: TMark read FMark write SetMark;
    constructor Create(AOwner: TComponent); override;
    procedure Delete(const AutoFree: Boolean = true);
  end;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  OlfAboutDialog1.Execute;
end;

procedure TfrmMain.actOptionsExecute(Sender: TObject);
var
  f: TfrmOptions;
begin
  f := TfrmOptions.Create(self);
  try
    f.showmodal;
  finally
    f.free;
  end;
end;

procedure TfrmMain.actProjectCloseExecute(Sender: TObject);
begin
  if assigned(CurrentProject) and CurrentProject.HasChanged then
  begin
    TDialogService.MessageDialog
      ('Current project has been changed. Do you want to save it ?',
      tmsgdlgtype.mtConfirmation, mbyesno, tmsgdlgbtn.mbYes, 0,
      procedure(const AModalResult: TModalResult)
      begin
        if AModalResult = mryes then
          if not CurrentProject.FilePath.IsEmpty then
            CurrentProject.SaveToFile
          else
          begin
            tthread.ForceQueue(nil,
              procedure
              begin
                actProjectSaveExecute(Sender);
              end);
            abort;
          end;
        CurrentProject.free;
        CurrentProject := nil;
      end);
  end
  else
  begin
    CurrentProject.free;
    CurrentProject := nil;
  end;
end;

procedure TfrmMain.actProjectExportExecute(Sender: TObject);
var
  Project: TVISPProject;
begin
  if not assigned(CurrentProject) then
    exit;

  Project := CurrentProject.Clone;
  try
    if Project.ExportedVideoPath.IsEmpty then
      Project.ExportedVideoPath := tconfig.DefaultExportFolder;

    if (not TDirectory.Exists(Project.ExportedVideoPath)) then
      raise exception.Create('The export video folder doesn''t exist !');

    // TODO : proposer un autoenregistrement du projet dans les options du programme ou voir si on pose la question

    FSplittingWorker.AddToQueue(Project);
  except
    Project.free;
    raise;
  end;
end;

procedure TfrmMain.actProjectNewExecute(Sender: TObject);
var
  Project: TVISPProject;
begin
  if assigned(CurrentProject) then
    actProjectCloseExecute(Sender);

  if odVideoFile.InitialDir.IsEmpty then
    odVideoFile.InitialDir := tconfig.DefaultSourceVideoFolder;

  if odVideoFile.Execute and (odVideoFile.FileName <> '') and
    tfile.Exists(odVideoFile.FileName) and
    (TPath.GetExtension(odVideoFile.FileName).ToLower = '.mp4') then
  begin
    Project := TVISPProject.Create;
    Project.SourceVideoFilePath := odVideoFile.FileName;
    CurrentProject := Project;
  end;
end;

procedure TfrmMain.actProjectOpenExecute(Sender: TObject);
var
  Project: TVISPProject;
begin
  if assigned(CurrentProject) then
    actProjectCloseExecute(Sender);

  if odVISPProject.InitialDir.IsEmpty then
    odVISPProject.InitialDir := tconfig.DefaultProjectFolder;

  if odVISPProject.Execute and (odVISPProject.FileName <> '') and
    tfile.Exists(odVISPProject.FileName) and
    (TPath.GetExtension(odVISPProject.FileName).ToLower = '.visp') then
  begin
    Project := TVISPProject.Create(odVISPProject.FileName);
    if tfile.Exists(Project.SourceVideoFilePath) then
      CurrentProject := Project
    else
      TDialogService.ShowMessage
        ('Can''t find the video source file. Please select it.',
        procedure(const AModalResult: TModalResult)
        var
          fld: string;
        begin
          fld := TPath.GetDirectoryName(Project.SourceVideoFilePath);
          if odVideoFile.InitialDir.IsEmpty then
            if (not fld.IsEmpty) and TDirectory.Exists(fld) then
              odVideoFile.InitialDir := fld
            else
              odVideoFile.InitialDir := tconfig.DefaultSourceVideoFolder;

          if odVideoFile.Execute and (odVideoFile.FileName <> '') and
            tfile.Exists(odVideoFile.FileName) and
            (TPath.GetExtension(odVideoFile.FileName).ToLower = '.mp4') then
          begin
            Project.SourceVideoFilePath := odVideoFile.FileName;
            CurrentProject := Project;
          end
          else
            Project.free;
        end);
  end;
end;

procedure TfrmMain.actProjectOptionsExecute(Sender: TObject);
var
  f: TfrmProjectOptions;
begin
  f := TfrmProjectOptions.Create(self, CurrentProject);
  try
    f.showmodal;
  finally
    f.free;
  end;
end;

procedure TfrmMain.actProjectSaveExecute(Sender: TObject);
begin
  if not assigned(CurrentProject) then
    exit;

  if not CurrentProject.FilePath.IsEmpty then
    CurrentProject.SaveToFile
  else
  begin
    if sdVISPProject.InitialDir.IsEmpty then
      sdVISPProject.InitialDir := tconfig.DefaultProjectFolder;

    sdVISPProject.FileName := TPath.GetFileNameWithoutExtension
      (CurrentProject.SourceVideoFilePath) + '.visp';

    if sdVISPProject.Execute and (sdVISPProject.FileName <> '') then
      CurrentProject.SaveToFile(sdVISPProject.FileName);
  end;
end;

procedure TfrmMain.actQuitExecute(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.AddLog(const Text: string);
begin
{$IFDEF DEBUG}
  ShowMessage(Text);
{$ENDIF}
end;

procedure TfrmMain.AddMark(const ATime: int64);
var
  Mark: TMark;
  MarkItem: TMarkItem;
begin
  if not assigned(FCurrentProject) then
    raise exception.Create('Project needed !');

  if not assigned(FCurrentProject.Marks.GetMark(ATime, false)) then
  begin
    Mark := FCurrentProject.Marks.GetMark(ATime, true);
    if assigned(Mark) then
    begin
      Mark.ToClip := FCurrentProject.Marks.GetPreviousMark(ATime).ToClip;
      MarkItem := TMarkItem.Create(self);
      MarkItem.Mark := Mark;
{$REGION 'RSS-1355 temporary patch'}
      // TODO : temporary patch to remove when the bug will be fixed
      // https://embt.atlassian.net/servicedesk/customer/portal/1/RSS-1355
      lbVideoParts.ItemIndex := -1;
{$ENDREGION}
      lbVideoParts.AddObject(MarkItem);
    end;
  end;
end;

procedure TfrmMain.btnAddMarkClick(Sender: TObject);
begin
  AddMark(CurrentTime);
end;

procedure TfrmMain.btnGotoEndClick(Sender: TObject);
begin
  if MediaPlayer1.State = TMediaState.Playing then
    btnPlayPauseClick(Sender);
  CurrentTime := VideoDuration;
end;

procedure TfrmMain.btnGotoStartClick(Sender: TObject);
begin
  if MediaPlayer1.State = TMediaState.Playing then
    btnPlayPauseClick(Sender);
  CurrentTime := 0;
end;

procedure TfrmMain.btnNextFrameClick(Sender: TObject);
var
  FrameDuration: int64;
begin
  FrameDuration := round((1 / CurrentProject.VideoFPS) * mediatimescale);
  CurrentTime := CurrentTime + FrameDuration;
end;

procedure TfrmMain.btnNextSecondeClick(Sender: TObject);
begin
  CurrentTime := CurrentTime + mediatimescale;
end;

procedure TfrmMain.btnPlayPauseClick(Sender: TObject);
begin
  if MediaPlayer1.State = TMediaState.Playing then
  begin
    MediaPlayer1.Stop;
    pPause.Visible := false;
  end
  else
  begin
    MediaPlayer1.Play;
    pPause.Visible := true;
  end;
  pPlay.Visible := not pPause.Visible;
end;

procedure TfrmMain.btnPrevFrameClick(Sender: TObject);
var
  FrameDuration: int64;
begin
  FrameDuration := round((1 / CurrentProject.VideoFPS) * mediatimescale);
  CurrentTime := CurrentTime - FrameDuration;
end;

procedure TfrmMain.btnPrevSecondeClick(Sender: TObject);
begin
  CurrentTime := CurrentTime - mediatimescale;
end;

procedure TfrmMain.btnRemoveMarkClick(Sender: TObject);
begin
  if not assigned(FCurrentProject) then
    raise exception.Create('Project needed !');

  if assigned(lbVideoParts.Selected) and (lbVideoParts.Selected is TMarkItem)
    and assigned((lbVideoParts.Selected as TMarkItem).Mark) and
    ((lbVideoParts.Selected as TMarkItem).Mark.Time <> 0) then
    (lbVideoParts.Selected as TMarkItem).Delete(true);
end;

procedure TfrmMain.CheckVideoPositionTimerTimer(Sender: TObject);
begin
  if assigned(CurrentProject) and (MediaPlayer1.State = TMediaState.Playing)
  then
  begin
    if (CurrentTime >= VideoDuration) then
    begin
      btnPlayPauseClick(Sender);
      CurrentTime := VideoDuration;
    end
    else
      UpdateTrackbarValue(CurrentTime);
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FSplittingWorker.Stop;
  sleep(1000); // wait for thread termination
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if AniIndicator1.Enabled then
  begin
    CanClose := false;
    ShowMessage('Waiting for current waiting list is empty.');
    tthread.ForceQueue(nil,
      procedure
      begin
        sleep(1000);
        close;
      end);
  end
  else if assigned(CurrentProject) then
  begin
    actProjectCloseExecute(Sender);
    CanClose := not assigned(CurrentProject);
  end
  else
    CanClose := true;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SubscribeToProjectChangedMessage;
  CurrentProject := nil;

  InitMainFormCaption;
  InitAboutDialogDescriptionAndLicense;
  InitMainMenuForMacOS;

  WaitingListCount := 0;

  FSplittingWorker := TSplittingWorker.Create;
  FSplittingWorker.OnWorkStart := procedure
    begin
      AniIndicator1.Visible := true;
      AniIndicator1.Enabled := true;
    end;
  FSplittingWorker.OnWorkEnd := procedure
    begin
      AniIndicator1.Enabled := false;
      AniIndicator1.Visible := false;
    end;
  FSplittingWorker.OnWaitingListCountChange := procedure(Count: nativeint)
    begin
      WaitingListCount := Count;
    end;
  FSplittingWorker.onError := procedure(Text: string)
    begin
      AddLog('***** ERROR *****');
      AddLog(Text);
    end;
  FSplittingWorker.onLog := procedure(Text: string)
    begin
      AddLog(Text);
    end;
  FSplittingWorker.Start;
end;

function TfrmMain.GetCurrentTime: int64;
begin
  result := MediaPlayer1.CurrentTime;
end;

procedure TfrmMain.InitAboutDialogDescriptionAndLicense;
begin
  OlfAboutDialog1.Licence.Text :=
    'This program is distributed as shareware. If you use it (especially for ' +
    'commercial or income-generating purposes), please remember the author and '
    + 'contribute to its development by purchasing a license.' + slinebreak +
    slinebreak +
    'This software is supplied as is, with or without bugs. No warranty is offered '
    + 'as to its operation or the data processed. Make backups!';
  OlfAboutDialog1.Description.Text :=
    'Video Splitter allows its users to define part of a video and export them '
    + 'as independant video files (like shorts or clips). The program is a GUI '
    + 'over FFmpeg command line interface.' + slinebreak + slinebreak +
    '*****************' + slinebreak + '* Publisher info' + slinebreak +
    slinebreak + 'This application was developed by Patrick Prémartin.' +
    slinebreak + slinebreak +
    'It is published by OLF SOFTWARE, a company registered in Paris (France) under the reference 439521725.'
    + slinebreak + slinebreak + '****************' + slinebreak +
    '* Personal data' + slinebreak + slinebreak +
    'This program is autonomous in its current version. It does not depend on the Internet and communicates nothing to the outside world.'
    + slinebreak + slinebreak + 'We have no knowledge of what you do with it.' +
    slinebreak + slinebreak +
    'No information about you is transmitted to us or to any third party.' +
    slinebreak + slinebreak +
    'We use no cookies, no tracking, no stats on your use of the application.' +
    slinebreak + slinebreak + '**********************' + slinebreak +
    '* User support' + slinebreak + slinebreak +
    'If you have any questions or require additional functionality, please leave us a message on the application''s website or on its code repository.'
    + slinebreak + slinebreak + 'To find out more, visit ' +
    OlfAboutDialog1.URL;
end;

procedure TfrmMain.InitMainFormCaption;
begin
{$IFDEF DEBUG}
  caption := '[DEBUG] ';
{$ELSE}
  caption := '';
{$ENDIF}
  if assigned(CurrentProject) then
  begin
    caption := caption + CurrentProject.FileName + ' ';
    if CurrentProject.HasChanged then
      caption := caption + '(*) ';
    caption := caption + ' - ';
  end;

  caption := caption + OlfAboutDialog1.Titre + ' v' +
    OlfAboutDialog1.VersionNumero;
end;

procedure TfrmMain.InitMainMenuForMacOS;
begin
{$IFDEF MACOS}
  mnuMacOS.Visible := true;
  actQuit.shortcut := scCommand + ord('Q'); // 4177;
  mnuHelpAbout.Parent := mnuMacOS;
  mnuHelp.Visible := (mnuHelp.Children[0].ChildrenCount > 0);
  mnuToolsOptions.Parent := mnuMacOS;
  mnuTools.Visible := (mnuTools.Children[0].ChildrenCount > 0);
{$ELSE}
  mnuMacOS.Visible := false;
{$ENDIF}
  actAbout.Text := '&About ' + OlfAboutDialog1.Titre;
  btnAbout.Text := '&About';
end;

procedure TfrmMain.InitVideoParts;
var
  Item: TMarkItem;
  Mark: TMark;
begin
  lbVideoParts.clear;

  if not assigned(CurrentProject) then
    raise exception.Create('No project opened.');

  lbVideoParts.BeginUpdate;
  try
    for Mark in CurrentProject.Marks do
    begin
      Item := TMarkItem.Create(self);
      Item.Mark := Mark;
      lbVideoParts.AddObject(Item);
    end;
  finally
    lbVideoParts.EndUpdate;
  end;
end;

procedure TfrmMain.lbVideoPartsChangeCheck(Sender: TObject);
begin
  if Sender is TMarkItem then
    (Sender as TMarkItem).CheckboxChange(Sender);
end;

procedure TfrmMain.lbVideoPartsItemClick(const Sender: TCustomListBox;
const Item: TListBoxItem);
begin
  if (Item is TMarkItem) then
    CurrentTime := (Item as TMarkItem).Mark.Time;
end;

procedure TfrmMain.OlfAboutDialog1URLClick(const AURL: string);
begin
  url_Open_In_Browser(AURL);
end;

procedure TfrmMain.UpdateTrackbarValue(const CurTime: int64);
begin
  FTrackingFromMediaPlayer := true;
  try
    tbVideo.Value := CurTime / mediatimescale;
    lblStatus.Text := SecondesToHHMMSS(tbVideo.Value) + ' / ' +
      SecondesToHHMMSS(VideoDurationSecondes);
  finally
    FTrackingFromMediaPlayer := false;
  end;
end;

procedure TfrmMain.SetCurrentProject(const Value: TVISPProject);
begin
  FCurrentProject := Value;

  if not assigned(FCurrentProject) then
  begin
    if MediaPlayer1.State = TMediaState.Playing then
      MediaPlayer1.Stop;
    tconfig.save; // sauve les options du programme liées à l'écran de projet
    lProject.Visible := false;
    lblStatus.Text := '';
    CheckVideoPositionTimer.Enabled := false;
    TMessageManager.DefaultManager.SendMessage(self,
      TVISPProjectHasChangedMessage.Create(FCurrentProject));
  end
  else
  begin
    VideoDuration := 0;
    MediaPlayer1.FileName := FCurrentProject.SourceVideoFilePath;
    MediaPlayer1.Play;
    tthread.CreateAnonymousThread(
      procedure
      var
        i: integer;
        ok: Boolean;
      begin
        i := 0;
        ok := false;
        repeat
          sleep(100);
          tthread.Synchronize(nil,
            procedure
            begin
              if (MediaPlayer1.Duration > 0) then
              begin
                MediaPlayer1.Stop;
                VideoDuration := MediaPlayer1.Duration;
                ok := true;
              end;
            end);
          inc(i);
        until tthread.CheckTerminated or ok or (i > 600); // Wait 1 minute max
        if not ok then
          tthread.queue(nil,
            procedure
            begin // the video can't be read by TMediaPlayer
              CurrentProject.free;
              CurrentProject := nil;
            end)
        else
          tthread.queue(nil,
            procedure
            begin
              lProject.Visible := true;
              pPause.Visible := false;
              pPlay.Visible := true;

              CheckVideoPositionTimer.interval :=
                round((1 / CurrentProject.VideoFPS) * 1000);
              CheckVideoPositionTimer.Enabled := true;

              tbVideo.min := 0;
              tbVideo.Max := VideoDurationSecondes;
              CurrentTime := 0;

              tbVolume.Value := tconfig.PlayVolume;
              MediaPlayer1.Volume := tconfig.PlayVolume / 100;

              InitVideoParts;

              TMessageManager.DefaultManager.SendMessage(self,
                TVISPProjectHasChangedMessage.Create(FCurrentProject));
            end);
      end).Start;
  end;

end;

procedure TfrmMain.SetCurrentTime(const Value: int64);
var
  ct: int64;
begin
  if (Value < 1) then
    ct := 0
  else if (Value > VideoDuration) then
    ct := VideoDuration
  else
    ct := Value;

  MediaPlayer1.CurrentTime := ct;
  UpdateTrackbarValue(ct);

  // TODO : à retirer si on arrive à résoudre le positionnnement autrement
  // if not(MediaPlayer1.State = TMediaState.Playing) then
  // begin
  // MediaPlayer1.Play;
  // MediaPlayer1.Stop;
  // end;
end;

procedure TfrmMain.SetVideoDuration(const Value: int64);
begin
  FVideoDuration := Value;
  FVideoDurationSecondes := Value / mediatimescale;
end;

procedure TfrmMain.SetWaitingListCount(const Value: nativeint);
begin
  lblWaitingListStatus.Text := 'Waiting count : ' + Value.tostring;
end;

procedure TfrmMain.SubscribeToProjectChangedMessage;
begin
  TMessageManager.DefaultManager.SubscribeToMessage
    (TVISPProjectHasChangedMessage,
    procedure(const Sender: TObject; const M: TMessage)
    var
      msg: TVISPProjectHasChangedMessage;
    begin
      if M is TVISPProjectHasChangedMessage then
        msg := M as TVISPProjectHasChangedMessage
      else
        raise exception.Create('Wrong message for subscription !');

      if msg.Value = CurrentProject then
        InitMainFormCaption;

      if assigned(CurrentProject) then
        lblSourceFile.Text := TPath.GetFileName
          (CurrentProject.SourceVideoFilePath)
      else
        lblSourceFile.Text := '';

      actProjectSave.Enabled := assigned(CurrentProject);
      actProjectOptions.Enabled := assigned(CurrentProject);
      actProjectClose.Enabled := assigned(CurrentProject);

      mnuProject.Enabled := assigned(CurrentProject);

      btnProjectOpen.Visible := not assigned(CurrentProject);
      btnProjectNew.Visible := btnProjectOpen.Visible;
      btnProjectClose.Visible := not btnProjectOpen.Visible;
      btnProjectOptions.Visible := not btnProjectOpen.Visible;
      btnProjectExport.Visible := not btnProjectOpen.Visible;
    end);
end;

procedure TfrmMain.tbVideoTracking(Sender: TObject);
begin
  if FTrackingFromMediaPlayer then
    exit;

  CurrentTime := round(tbVideo.Value * mediatimescale);
end;

procedure TfrmMain.tbVolumeTracking(Sender: TObject);
begin
  tconfig.PlayVolume := round(tbVolume.Value);
  MediaPlayer1.Volume := tconfig.PlayVolume / 100;
end;

{ TMarkItem }

procedure TMarkItem.CheckboxChange(Sender: TObject);
begin
  Mark.ToClip := IsChecked;
end;

constructor TMarkItem.Create(AOwner: TComponent);
begin
  inherited;
  FMark := nil;
end;

procedure TMarkItem.Delete(const AutoFree: Boolean);
begin
  if assigned(FMark) then
    FMark.Delete(AutoFree);

  if AutoFree then
    free;
end;

procedure TMarkItem.SetMark(const Value: TMark);
begin
  if assigned(Value) then
  begin
    FMark := Value;
    Text := SecondesToHHMMSS(FMark.Time / mediatimescale);
    IsChecked := FMark.ToClip;
  end
  else
  begin
    Text := 'undefined';
    IsChecked := false;
  end;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}
TDialogService.PreferredMode := TDialogService.TPreferredMode.Sync;

end.
