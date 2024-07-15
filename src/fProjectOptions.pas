unit fProjectOptions;

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
  uProjectVISP, Olf.FMX.SelectDirectory;

type
  TfrmProjectOptions = class(TForm)
    VertScrollBox1: TVertScrollBox;
    GridPanelLayout1: TGridPanelLayout;
    btnSaveAndClose: TButton;
    btnCancel: TButton;
    lblFPS: TLabel;
    edtFPS: TEdit;
    lblExportVideoFolder: TLabel;
    edtExportVideoFolder: TEdit;
    btnExportVideoFolder: TEllipsesEditButton;
    OlfSelectDirectoryDialog1: TOlfSelectDirectoryDialog;
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveAndCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnExportVideoFolderClick(Sender: TObject);
  private
    FCurrentProject: TVISPProject;
    procedure SaveConfig;
    procedure InitConfigFields;
    function HasChanged: Boolean;
    procedure SetCurrentProject(const Value: TVISPProject);
  public
    property CurrentProject: TVISPProject read FCurrentProject
      write SetCurrentProject;
    constructor Create(const AOwner: TComponent;
      const ACurrentProject: TVISPProject);
  end;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  System.IOUtils,
  u_urlOpen,
  uconfig;

procedure TfrmProjectOptions.btnCancelClick(Sender: TObject);
begin
  InitConfigFields;
  close;
end;

procedure TfrmProjectOptions.btnExportVideoFolderClick(Sender: TObject);
begin
  if (not edtExportVideoFolder.Text.IsEmpty) and
    tdirectory.Exists(edtExportVideoFolder.Text) then
    OlfSelectDirectoryDialog1.Directory := edtExportVideoFolder.Text;

  if OlfSelectDirectoryDialog1.Execute and
    tdirectory.Exists(OlfSelectDirectoryDialog1.Directory) then
    edtExportVideoFolder.Text := OlfSelectDirectoryDialog1.Directory;
end;

procedure TfrmProjectOptions.btnSaveAndCloseClick(Sender: TObject);
begin
  SaveConfig;
  close;
end;

constructor TfrmProjectOptions.Create(const AOwner: TComponent;
  const ACurrentProject: TVISPProject);
begin
  inherited Create(AOwner);
  CurrentProject := ACurrentProject;
end;

procedure TfrmProjectOptions.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
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

procedure TfrmProjectOptions.FormCreate(Sender: TObject);
begin
  InitConfigFields;
end;

function TfrmProjectOptions.HasChanged: Boolean;
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

procedure TfrmProjectOptions.InitConfigFields;
var
  i: integer;
  e: TEdit;
begin
  edtExportVideoFolder.TagString := CurrentProject.ExportedVideoPath;
  edtFPS.TagString := CurrentProject.VideoFPS.ToString;

  for i := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
    if VertScrollBox1.Content.Children[i] is TEdit then
    begin
      e := VertScrollBox1.Content.Children[i] as TEdit;
      e.Text := e.TagString;
    end;
end;

procedure TfrmProjectOptions.SaveConfig;
begin
  CurrentProject.ExportedVideoPath := edtExportVideoFolder.Text;
  CurrentProject.VideoFPS := edtFPS.Text.ToInteger;
  if CurrentProject.VideoFPS = tconfig.DefaultVideoFPS then
    CurrentProject.HasChanged := true;

  InitConfigFields;
end;

procedure TfrmProjectOptions.SetCurrentProject(const Value: TVISPProject);
begin
  if not assigned(Value) then
    raise Exception.Create('Project needed !');

  FCurrentProject := Value;
end;

end.
