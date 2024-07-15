unit fOptions;

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
  FMX.Layouts,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Controls.Presentation,
  Olf.FMX.SelectDirectory;

type
  TfrmOptions = class(TForm)
    VertScrollBox1: TVertScrollBox;
    GridPanelLayout1: TGridPanelLayout;
    lblFFmpegPath: TLabel;
    btnFFmpegDownload: TButton;
    edtFFmpegPath: TEdit;
    btnFFmpegPathChoose: TEllipsesEditButton;
    btnSaveAndClose: TButton;
    btnCancel: TButton;
    OpenDialogFFmpeg: TOpenDialog;
    lblDefaultProjectFolder: TLabel;
    edtDefaultProjectFolder: TEdit;
    btnDefaultProjectFolder: TEllipsesEditButton;
    lblDefaultSourceVideoFolder: TLabel;
    edtDefaultSourceVideoFolder: TEdit;
    btnDefaultSourceVideoFolder: TEllipsesEditButton;
    lblDefaultExportFolder: TLabel;
    edtDefaultExportFolder: TEdit;
    btnDefaultExportFolder: TEllipsesEditButton;
    OlfSelectDirectoryDialog1: TOlfSelectDirectoryDialog;
    lblDefaultFPS: TLabel;
    edtDefaultFPS: TEdit;
    procedure btnFFmpegDownloadClick(Sender: TObject);
    procedure btnFFmpegPathChooseClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveAndCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnDefaultProjectFolderClick(Sender: TObject);
    procedure btnDefaultSourceVideoFolderClick(Sender: TObject);
    procedure btnDefaultExportFolderClick(Sender: TObject);
  private
    procedure SaveConfig;
    procedure InitConfigFields;
    function HasChanged: Boolean;
  public
  end;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  System.IOUtils,
  u_urlOpen,
  uConfig;

procedure TfrmOptions.btnCancelClick(Sender: TObject);
begin
  InitConfigFields;
  close;
end;

procedure TfrmOptions.btnDefaultExportFolderClick(Sender: TObject);
begin
  if (not edtDefaultExportFolder.Text.IsEmpty) and
    tdirectory.Exists(edtDefaultExportFolder.Text) then
    OlfSelectDirectoryDialog1.Directory := edtDefaultExportFolder.Text;

  if OlfSelectDirectoryDialog1.Execute and
    tdirectory.Exists(OlfSelectDirectoryDialog1.Directory) then
    edtDefaultExportFolder.Text := OlfSelectDirectoryDialog1.Directory;
end;

procedure TfrmOptions.btnDefaultProjectFolderClick(Sender: TObject);
begin
  if (not edtDefaultProjectFolder.Text.IsEmpty) and
    tdirectory.Exists(edtDefaultProjectFolder.Text) then
    OlfSelectDirectoryDialog1.Directory := edtDefaultProjectFolder.Text;

  if OlfSelectDirectoryDialog1.Execute and
    tdirectory.Exists(OlfSelectDirectoryDialog1.Directory) then
    edtDefaultProjectFolder.Text := OlfSelectDirectoryDialog1.Directory;
end;

procedure TfrmOptions.btnDefaultSourceVideoFolderClick(Sender: TObject);
begin
  if (not edtDefaultSourceVideoFolder.Text.IsEmpty) and
    tdirectory.Exists(edtDefaultSourceVideoFolder.Text) then
    OlfSelectDirectoryDialog1.Directory := edtDefaultSourceVideoFolder.Text;

  if OlfSelectDirectoryDialog1.Execute and
    tdirectory.Exists(OlfSelectDirectoryDialog1.Directory) then
    edtDefaultSourceVideoFolder.Text := OlfSelectDirectoryDialog1.Directory;
end;

procedure TfrmOptions.btnFFmpegDownloadClick(Sender: TObject);
begin
  url_open_in_browser('https://ffmpeg.org/download.html');
end;

procedure TfrmOptions.btnFFmpegPathChooseClick(Sender: TObject);
begin
  if (not edtFFmpegPath.Text.IsEmpty) and tfile.Exists(edtFFmpegPath.Text) then
  begin
    OpenDialogFFmpeg.InitialDir := tpath.getdirectoryname(edtFFmpegPath.Text);
    OpenDialogFFmpeg.FileName := edtFFmpegPath.Text;
  end
  else if OpenDialogFFmpeg.InitialDir.IsEmpty then
    OpenDialogFFmpeg.InitialDir := tpath.GetDownloadsPath;

  if OpenDialogFFmpeg.Execute and tfile.Exists(OpenDialogFFmpeg.FileName) then
    edtFFmpegPath.Text := OpenDialogFFmpeg.FileName;
end;

procedure TfrmOptions.btnSaveAndCloseClick(Sender: TObject);
begin
  SaveConfig;
  close;
end;

procedure TfrmOptions.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if HasChanged then
  begin
    CanClose := false;
    TDialogService.MessageDialog
      ('Do you want to save your changes before closing ?',
      tmsgdlgtype.mtConfirmation, mbyesno, tmsgdlgbtn.mbYes, 0,
      procedure(const AModalResult: TModalResult)
      begin
        case AModalResult of
          mryes:
            tthread.forcequeue(nil,
              procedure
              begin
                btnSaveAndCloseClick(Sender);
              end);
        else
          tthread.forcequeue(nil,
            procedure
            begin
              btnCancelClick(Sender);
            end);
        end;
      end);
  end
  else
    CanClose := true;
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  InitConfigFields;
end;

function TfrmOptions.HasChanged: Boolean;
var
  i: integer;
  e: TEdit;
begin
  result := false;
  for i := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
    if VertScrollBox1.Content.Children[i] is TEdit then
    begin
      e := VertScrollBox1.Content.Children[i] as TEdit;
      result := e.TagString <> e.Text;
      if result then
        break;
    end;
end;

procedure TfrmOptions.InitConfigFields;
var
  i: integer;
  e: TEdit;
begin
  edtFFmpegPath.TagString := tconfig.FFmpegPath;
  edtDefaultProjectFolder.TagString := tconfig.DefaultProjectFolder;
  edtDefaultSourceVideoFolder.TagString := tconfig.DefaultSourceVideoFolder;
  edtDefaultExportFolder.TagString := tconfig.DefaultExportFolder;
  edtDefaultFPS.TagString := tconfig.DefaultVideoFPS.ToString;

  for i := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
    if VertScrollBox1.Content.Children[i] is TEdit then
    begin
      e := VertScrollBox1.Content.Children[i] as TEdit;
      e.Text := e.TagString;
    end;
end;

procedure TfrmOptions.SaveConfig;
begin
  tconfig.DefaultProjectFolder := edtDefaultProjectFolder.Text;
  tconfig.DefaultSourceVideoFolder := edtDefaultSourceVideoFolder.Text;
  tconfig.DefaultExportFolder := edtDefaultExportFolder.Text;
  tconfig.FFmpegPath := edtFFmpegPath.Text;
  tconfig.DefaultVideoFPS := edtDefaultFPS.Text.ToInteger;
  tconfig.Save;

  InitConfigFields;
end;

end.
