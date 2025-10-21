(* C2PP
  ***************************************************************************

  Video Splitter

  Copyright 2024-2025 Patrick PREMARTIN under AGPL 3.0 license.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

  ***************************************************************************

  Author(s) :
  Patrick PREMARTIN

  Site :
  https://videosplitter.olfsoftware.fr

  Project site :
  https://github.com/DeveloppeurPascal/Video-Splitter

  ***************************************************************************
  File last update : 2025-10-16T10:43:17.974+02:00
  Signature : 2ddc93fb520fcfeb0f228b647830adc293c95f27
  ***************************************************************************
*)

unit uSplitterWorker;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  uProjectVISP;

type
  TSplittingWorker = class(TThread)
  private
    FWaitingList: TObjectQueue<TVISPProject>;
    FOnWorkStart: TProc;
    FOnWaitingListCountChange: TProc<Nativeint>;
    FOnWorkEnd: TProc;
    FonError: TProc<string>;
    FonLog: TProc<string>;
    procedure SetonError(const Value: TProc<string>);
    procedure SetOnWaitingListCountChange(const Value: TProc<Nativeint>);
    procedure SetOnWorkEnd(const Value: TProc);
    procedure SetOnWorkStart(const Value: TProc);
    procedure SetonLog(const Value: TProc<string>);
  protected
    function GetNextFromQueue: TVISPProject;
    procedure Execute; override;
    procedure AddLog(Text: string);
    procedure AddError(Text: string);
    procedure ExecuteFFmpegAndWait(const AParams, DestinationFilePath: string);
  public
    property OnWorkStart: TProc read FOnWorkStart write SetOnWorkStart;
    property OnWorkEnd: TProc read FOnWorkEnd write SetOnWorkEnd;
    property OnWaitingListCountChange: TProc<Nativeint>
      read FOnWaitingListCountChange write SetOnWaitingListCountChange;
    property onError: TProc<string> read FonError write SetonError;
    property onLog: TProc<string> read FonLog write SetonLog;
    procedure AddToQueue(const Project: TVISPProject);
    constructor Create;
    destructor Destroy; override;
    procedure Stop;
  end;

implementation

uses
{$IF Defined(MACOS)}
  Posix.Stdlib,
{$ELSEIF Defined(MSWINDOWS)}
  DosCommand,
{$ENDIF}
  System.IOUtils,
  System.Types,
  FMX.Media,
  System.Generics.Defaults,
  uConfig,
  uTools;

procedure TSplittingWorker.AddError(Text: string);
begin
  if assigned(FonError) and (not Text.IsEmpty) then
    TThread.Queue(nil,
      procedure
      begin
        if assigned(FonError) then
          FonError(Text);
      end);
end;

procedure TSplittingWorker.AddLog(Text: string);
begin
  if assigned(FonLog) and (not Text.IsEmpty) then
    TThread.Queue(nil,
      procedure
      begin
        if assigned(FonLog) then
          FonLog(Text);
      end);
end;

procedure TSplittingWorker.AddToQueue(const Project: TVISPProject);
var
  Count: Nativeint;
begin
  if not assigned(Project) then
    exit;

  System.TMonitor.Enter(FWaitingList);
  try
    FWaitingList.Enqueue(Project);
    if assigned(FOnWaitingListCountChange) then
    begin
      Count := FWaitingList.Count;
      TThread.Queue(nil,
        procedure
        begin
          if assigned(FOnWaitingListCountChange) then
            FOnWaitingListCountChange(Count);
        end);
    end;
  finally
    System.TMonitor.exit(FWaitingList);
  end;
end;

constructor TSplittingWorker.Create;
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FWaitingList := TObjectQueue<TVISPProject>.Create;
  FOnWorkStart := nil;
  FOnWaitingListCountChange := nil;
  FOnWorkEnd := nil;
  FonError := nil;
  FonLog := nil;
end;

destructor TSplittingWorker.Destroy;
begin
  FWaitingList.free;
  inherited;
end;

procedure TSplittingWorker.Execute;
var
  Project: TVISPProject;
  cmd: string;
  i: integer;
  Mark: TMark;
  TimeList: TList<int64>;
  TimeStart, TimeEnd: string;
  ToFilePath: string;
begin
  while not TThread.CheckTerminated do
  begin
    Project := GetNextFromQueue;
    if not assigned(Project) then
      sleep(1000)
    else
      try
        TimeList := TList<int64>.Create;
        try
          for Mark in Project.Marks do
            TimeList.Add(Mark.Time);

          TimeList.Sort(TComparer<int64>.Construct(
            function(const Left, Right: int64): integer
            begin
              if Left < Right then
                result := -1
              else if Left > Right then
                result := 1
              else
                result := 0;
            end));

          for i := 0 to TimeList.Count - 1 do
          begin
            Mark := Project.Marks.GetMark(TimeList[i], false);
            if Mark.ToClip then
            begin
              cmd := '';
              // Start of the block
              TimeStart := SecondesToHHMMSS(Mark.Time / MediaTimeScale)
                .Replace(',', '.');
              cmd := cmd + ' -ss ' + TimeStart;
              // End of the block
              Mark := Project.Marks.GetNextMark(Mark.Time);
              if assigned(Mark) then
              begin
                TimeEnd := SecondesToHHMMSS(Mark.Time / MediaTimeScale)
                  .Replace(',', '.');
                cmd := cmd + ' -to ' + TimeEnd;
              end
              else
                TimeEnd := '';

              cmd := cmd + ' -i "' + Project.SourceVideoFilePath + '"';

              TimeStart := TimeStart.Replace(':', '').Replace('.', '');
              if TimeEnd.IsEmpty then
                ToFilePath := tpath.combine(Project.ExportedVideoPath,
                  Project.FileName + '-' + TimeStart + '.mp4')
              else
              begin
                TimeEnd := TimeEnd.Replace(':', '').Replace('.', '');
                ToFilePath := tpath.combine(Project.ExportedVideoPath,
                  Project.FileName + '-' + TimeStart + '-' + TimeEnd + '.mp4');
              end;

              if assigned(FOnWorkStart) then
                TThread.Queue(nil,
                  procedure
                  begin
                    if assigned(FOnWorkStart) then
                      FOnWorkStart;
                  end);
              try
                ExecuteFFmpegAndWait(cmd, ToFilePath);
                AddLog('Finished exporting "' +
                  tpath.GetFileName(ToFilePath) + '".');
              finally
                if assigned(FOnWorkEnd) then
                  TThread.Queue(nil,
                    procedure
                    begin
                      if assigned(FOnWorkEnd) then
                        FOnWorkEnd;
                    end);
              end;
            end;
          end;
        finally
          TimeList.free;
        end;
      finally
        Project.free;
      end;
  end;
end;

procedure TSplittingWorker.ExecuteFFmpegAndWait(const AParams,
  DestinationFilePath: string);
// procedure from "Le Temps D'Une Tomate" project
// cf https://github.com/DeveloppeurPascal/LeTempsDUneTomate/blob/main/src/fMain.pas
var
  LParams: string;
  cmd: string;
{$IFDEF MSWINDOWS}
  DosCommand: TDosCommand;
{$ENDIF}
begin
{$IFDEF DEBUG}
  LParams := '-y ' + AParams;
{$ELSE}
  LParams := '-y -loglevel error ' + AParams;
{$ENDIF}
  cmd := '"' + TConfig.FFmpegPath + '" ' + LParams + ' "' +
    DestinationFilePath + '"';
{$IFDEF DEBUG}
  AddLog(cmd);
{$ENDIF}
{$IF Defined(MSWINDOWS)}
  DosCommand := TDosCommand.Create(nil);
  try
    DosCommand.CommandLine := cmd;
    DosCommand.InputToOutput := false;
    try
      DosCommand.Execute;
    except
    end;
    while DosCommand.IsRunning and
      (DosCommand.EndStatus = TEndStatus.esStill_Active) do
      sleep(100);
  finally
    DosCommand.free;
  end;
{$ELSEIF Defined(MACOS)}
  _system(PAnsiChar(ansistring(cmd)));
{$ELSE}
{$MESSAGE FATAL 'Platform not available.'}
{$ENDIF}
end;

function TSplittingWorker.GetNextFromQueue: TVISPProject;
var
  Count: Nativeint;
begin
  System.TMonitor.Enter(FWaitingList);
  try
    Count := FWaitingList.Count;
    if (Count > 0) then
    begin
      result := FWaitingList.Extract;
      if assigned(FOnWaitingListCountChange) then
      begin
        Count := Count - 1;
        TThread.Queue(nil,
          procedure
          begin
            if assigned(FOnWaitingListCountChange) then
              FOnWaitingListCountChange(Count);
          end);
      end;
    end
    else
      result := nil;
  finally
    System.TMonitor.exit(FWaitingList);
  end;
end;

procedure TSplittingWorker.SetonError(const Value: TProc<string>);
begin
  FonError := Value;
end;

procedure TSplittingWorker.SetonLog(const Value: TProc<string>);
begin
  FonLog := Value;
end;

procedure TSplittingWorker.SetOnWaitingListCountChange
  (const Value: TProc<Nativeint>);
begin
  FOnWaitingListCountChange := Value;
end;

procedure TSplittingWorker.SetOnWorkEnd(const Value: TProc);
begin
  FOnWorkEnd := Value;
end;

procedure TSplittingWorker.SetOnWorkStart(const Value: TProc);
begin
  FOnWorkStart := Value;
end;

procedure TSplittingWorker.Stop;
begin
  terminate;
end;

end.
