unit uProjectVISP;

interface

uses
  System.Messaging,
  System.Classes,
  System.Generics.Collections;

const
  CProjectFileVersion = 20240711;

type
  TVISPProject = class;

  TVISPProjectHasChangedMessage = class(TMessage<TVISPProject>)
  end;

  TMark = class
  private const
    CVersion = 1;

  var
    FProject: TVISPProject;
    FTime: int64;
    FToClip: boolean;
    procedure SetToClip(const Value: boolean);
    procedure SetTime(const Value: int64);
  protected
  public
    property Time: int64 read FTime write SetTime;
    property ToClip: boolean read FToClip write SetToClip;
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToStream(const AStream: TStream);
    constructor Create(const AProject: TVISPProject);
    destructor Destroy; override;
    procedure Delete(const AutoFree: boolean = true);
  end;

  TMarkList = class(TObjectList<TMark>)
  private const
    CVersion = 1;

  var
    FProject: TVISPProject;
  protected
  public
    function GetNextMark(const ATime: int64): TMark;
    function GetPreviousMark(const ATime: int64): TMark;
    function GetMark(const ATime: int64;
      const CreateIfNotExists: boolean = false): TMark;
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToStream(const AStream: TStream);
    constructor Create(const AProject: TVISPProject);
    destructor Destroy; override;
    function Add(const Value: TMark): Integer; inline;
    procedure Delete(Index: Integer); inline;
    function Remove(const Value: TMark): Integer; inline;
    procedure Clear; inline;
  end;

  TVISPProject = class
  private const
    CVersion = 1;

  var
    FHasChanged: boolean;
    FIsLoading: boolean;
    FIsCloning: boolean;
    FFilePath: string;
    FSourceVideoFilePath: string;
    FExportedVideoPath: string;
    FMarks: TMarkList;
    FVideoFPS: Integer;
    procedure SetVideoFPS(const Value: Integer);
    function GetFileName: string;
    procedure SetMarks(const Value: TMarkList);
    procedure SetExportedVideoPath(const Value: string);
    procedure SetHasChanged(const Value: boolean);
    procedure SetSourceVideoFilePath(const Value: string);
  protected
  public
    property HasChanged: boolean read FHasChanged write SetHasChanged;
    property FilePath: string read FFilePath;
    property FileName: string read GetFileName;
    property SourceVideoFilePath: string read FSourceVideoFilePath
      write SetSourceVideoFilePath;
    property ExportedVideoPath: string read FExportedVideoPath
      write SetExportedVideoPath;
    property Marks: TMarkList read FMarks write SetMarks;
    property VideoFPS: Integer read FVideoFPS write SetVideoFPS;
    procedure LoadFromFile(const AFilePath: string = '');
    procedure LoadFromStream(const AStream: TStream);
    procedure SaveToStream(const AStream: TStream);
    procedure SaveToFile(const AFilePath: string = '');
    constructor Create; overload;
    constructor Create(const AFilePath: string); overload;
    destructor Destroy; override;
    function Clone: TVISPProject;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Olf.RTL.Streams,
  uConfig;

{ TMark }

constructor TMark.Create(const AProject: TVISPProject);
begin
  inherited Create;
  FProject := AProject;
  FTime := 0;
  FToClip := false;
end;

procedure TMark.Delete(const AutoFree: boolean);
begin
  if AutoFree then
    FProject.Marks.Remove(self)
  else
    FProject.Marks.Extract(self);
end;

destructor TMark.Destroy;
begin
  inherited;
end;

procedure TMark.LoadFromStream(const AStream: TStream);
var
  Version: byte;
begin
  if (AStream.Read(Version, sizeof(Version)) <> sizeof(Version)) then
    raise exception.Create('Wrong file format (undefined mark record).');

  if (Version > CVersion) then
    raise exception.Create
      ('This project file is too recent. Please upgrade this program if you wish to load it.');

  if (AStream.Read(FTime, sizeof(FTime)) <> sizeof(FTime)) then
    raise exception.Create('Wrong file format.');

  if (AStream.Read(FToClip, sizeof(FToClip)) <> sizeof(FToClip)) then
    raise exception.Create('Wrong file format.');
end;

procedure TMark.SaveToStream(const AStream: TStream);
var
  Version: byte;
begin
  Version := CVersion;
  AStream.Write(Version, sizeof(Version));
  AStream.Write(FTime, sizeof(FTime));
  AStream.Write(FToClip, sizeof(FToClip));
end;

procedure TMark.SetToClip(const Value: boolean);
begin
  if FToClip <> Value then
  begin
    FToClip := Value;
    if assigned(FProject) then
      FProject.HasChanged := true;
  end;
end;

procedure TMark.SetTime(const Value: int64);
begin
  if FTime <> Value then
  begin
    FTime := Value;
    if assigned(FProject) then
      FProject.HasChanged := true;
  end;
end;

{ TMarkList }

function TMarkList.Add(const Value: TMark): Integer;
begin
  result := inherited Add(Value);
  if assigned(FProject) then
    FProject.HasChanged := true;
end;

procedure TMarkList.Clear;
begin
  inherited Clear;
  if assigned(FProject) then
    FProject.HasChanged := true;
end;

constructor TMarkList.Create(const AProject: TVISPProject);
begin
  inherited Create;
  FProject := AProject;
  // On doit au moins avoir une marque au début du fichier.
  GetMark(0, true);
end;

procedure TMarkList.Delete(Index: Integer);
begin
  inherited Delete(index);
  if assigned(FProject) then
    FProject.HasChanged := true;
end;

destructor TMarkList.Destroy;
begin
  inherited;
end;

function TMarkList.GetMark(const ATime: int64;
  const CreateIfNotExists: boolean): TMark;
var
  Mark: TMark;
begin
  result := nil;
  for Mark in self do
    if Mark.Time = ATime then
    begin
      result := Mark;
      break;
    end;
  if (not assigned(result)) and CreateIfNotExists then
  begin
    result := TMark.Create(FProject);
    result.FTime := ATime;
    Add(result);
  end;
end;

function TMarkList.GetNextMark(const ATime: int64): TMark;
var
  Mark: TMark;
begin
  result := nil;
  for Mark in self do
    if (Mark.Time > ATime) and ((assigned(result) and (result.FTime > Mark.Time)
      ) or (not assigned(result))) then
      result := Mark;
end;

function TMarkList.GetPreviousMark(const ATime: int64): TMark;
var
  Mark: TMark;
begin
  result := nil;
  for Mark in self do
    if (Mark.Time < ATime) and ((assigned(result) and (result.FTime < Mark.Time)
      ) or (not assigned(result))) then
      result := Mark;
end;

procedure TMarkList.LoadFromStream(const AStream: TStream);
var
  Version: byte;
  I, Nb: int64;
  Mark: TMark;
begin
  if (AStream.Read(Version, sizeof(Version)) <> sizeof(Version)) then
    raise exception.Create('Wrong file format (undefined mark list).');

  if (Version > CVersion) then
    raise exception.Create
      ('This project file is too recent. Please upgrade this program if you wish to load it.');

  if (AStream.Read(Nb, sizeof(Nb)) <> sizeof(Nb)) then
    raise exception.Create('Wrong file format (no mark list).');

  Clear;
  for I := 1 to Nb do
  begin
    Mark := TMark.Create(FProject);
    Mark.LoadFromStream(AStream);
    Add(Mark);
  end;

  // On doit au moins avoir une marque au début du fichier.
  GetMark(0, true);
end;

function TMarkList.Remove(const Value: TMark): Integer;
begin
  result := inherited Remove(Value);
  if assigned(FProject) then
    FProject.HasChanged := true;
end;

procedure TMarkList.SaveToStream(const AStream: TStream);
var
  Version: byte;
  Nb: int64;
  Mark: TMark;
begin
  Version := CVersion;
  AStream.Write(Version, sizeof(Version));
  Nb := count;
  AStream.Write(Nb, sizeof(Nb));
  for Mark in self do
    Mark.SaveToStream(AStream);
end;

{ TVISPProject }

constructor TVISPProject.Create;
begin
  inherited;
  FHasChanged := false;
  FIsLoading := false;
  FIsCloning := false;
  FFilePath := '';
  FSourceVideoFilePath := '';
  FExportedVideoPath := '';
  FMarks := TMarkList.Create(self);
  FVideoFPS := tconfig.DefaultVideoFPS;
end;

function TVISPProject.Clone: TVISPProject;
var
  ms: TMemoryStream;
begin
  FIsCloning := true;
  try
    result := TVISPProject.Create;
    ms := TMemoryStream.Create;
    try
      SaveToStream(ms);
      ms.Position := 0;
      result.LoadFromStream(ms);
    finally
      ms.free;
    end;
    result.FFilePath := FFilePath;
    result.FHasChanged := false;
  finally
    FIsCloning := false;
  end;
end;

constructor TVISPProject.Create(const AFilePath: string);
begin
  Create;
  LoadFromFile(AFilePath);
end;

destructor TVISPProject.Destroy;
begin
  FMarks.free;
  inherited;
end;

function TVISPProject.GetFileName: string;
begin
  if FFilePath.isempty then
    result := 'noname'
  else
    result := tpath.GetFileNameWithoutExtension(FFilePath);
end;

procedure TVISPProject.LoadFromFile(const AFilePath: string);
var
  fs: TFileStream;
begin
  if not AFilePath.isempty then
    FFilePath := AFilePath;

  if FFilePath.isempty then
    raise exception.Create('No filename, what do you want to load ?');

  if not tfile.Exists(FFilePath) then
    raise exception.Create('This file doesn''t exist !');

  fs := TFileStream.Create(FFilePath, fmOpenRead);
  try
    LoadFromStream(fs);
  finally
    fs.free;
  end;
end;

procedure TVISPProject.LoadFromStream(const AStream: TStream);
var
  ProjectVersion: uint64;
  Version: byte;
begin
  FIsLoading := true;
  try
    if (AStream.Read(ProjectVersion, sizeof(ProjectVersion)) <>
      sizeof(ProjectVersion)) then
      raise exception.Create('Wrong file format.');

    if (ProjectVersion > CProjectFileVersion) then
      raise exception.Create
        ('This project file is too recent. Please upgrade this program if you wish to load it.');

    if (AStream.Read(Version, sizeof(Version)) <> sizeof(Version)) then
      raise exception.Create('Wrong file format (undefined project record).');

    if (Version > CVersion) then
      raise exception.Create
        ('This project file is too recent. Please upgrade this program if you wish to load it.');

    FSourceVideoFilePath := LoadStringFromStream(AStream);
    FExportedVideoPath := LoadStringFromStream(AStream);
    FMarks.LoadFromStream(AStream);

    if (AStream.Read(FVideoFPS, sizeof(FVideoFPS)) <> sizeof(FVideoFPS)) then
      raise exception.Create('Wrong file format.');

  finally
    FIsLoading := false;
  end;
  HasChanged := false;
end;

procedure TVISPProject.SaveToFile(const AFilePath: string);
var
  fs: TFileStream;
begin
  if not AFilePath.isempty then
    FFilePath := AFilePath;

  if FFilePath.isempty then
    raise exception.Create
      ('No filename, where do you want to save your project ?');

  fs := TFileStream.Create(FFilePath, fmOpenWrite + fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.free;
  end;
end;

procedure TVISPProject.SaveToStream(const AStream: TStream);
var
  ProjectVersion: uint64;
  Version: byte;
begin
  ProjectVersion := CProjectFileVersion;
  AStream.Write(ProjectVersion, sizeof(ProjectVersion));
  Version := CVersion;
  AStream.Write(Version, sizeof(Version));
  SaveStringToStream(FSourceVideoFilePath, AStream);
  SaveStringToStream(FExportedVideoPath, AStream);
  FMarks.SaveToStream(AStream);
  AStream.Write(FVideoFPS, sizeof(FVideoFPS));

  if not FIsCloning then
    HasChanged := false;
end;

procedure TVISPProject.SetExportedVideoPath(const Value: string);
begin
  if FExportedVideoPath <> Value then
  begin
    FExportedVideoPath := Value;
    HasChanged := true;
  end;
end;

procedure TVISPProject.SetHasChanged(const Value: boolean);
begin
  if (FHasChanged <> Value) then
  begin
    FHasChanged := Value;

    if FIsLoading then
      exit;

    tthread.ForceQueue(nil,
      procedure
      begin
        TMessageManager.DefaultManager.SendMessage(self,
          TVISPProjectHasChangedMessage.Create(self));
      end);
  end;
end;

procedure TVISPProject.SetMarks(const Value: TMarkList);
begin
  FMarks := Value;
end;

procedure TVISPProject.SetSourceVideoFilePath(const Value: string);
begin
  if FSourceVideoFilePath <> Value then
  begin
    FSourceVideoFilePath := Value;
    HasChanged := true;
  end;
end;

procedure TVISPProject.SetVideoFPS(const Value: Integer);
begin
  if FVideoFPS <> Value then
  begin
    FVideoFPS := Value;
    HasChanged := true;
  end;
end;

end.
