unit uConfig;

interface

type
  TConfig = class
  private
    class procedure SetFFmpegPath(const Value: string); static;
    class function GetFFmpegPath: string; static;
    class procedure SetDefaultExportFolder(const Value: string); static;
    class procedure SetDefaultProjectFolder(const Value: string); static;
    class procedure SetDefaultSourceVideoFolder(const Value: string); static;
    class function GetDefaultExportFolder: string; static;
    class function GetDefaultProjectFolder: string; static;
    class function GetDefaultSourceVideoFolder: string; static;
    class procedure SetDefaultVideoFPS(const Value: integer); static;
    class function GetDefaultVideoFPS: integer; static;
    class procedure SetPlayVolume(const Value: byte); static;
    class function GetPlayVolume: byte; static;
  protected
  public
    class property FFmpegPath: string read GetFFmpegPath write SetFFmpegPath;
    class property DefaultProjectFolder: string read GetDefaultProjectFolder
      write SetDefaultProjectFolder;
    class property DefaultSourceVideoFolder: string
      read GetDefaultSourceVideoFolder write SetDefaultSourceVideoFolder;
    class property DefaultExportFolder: string read GetDefaultExportFolder
      write SetDefaultExportFolder;
    class property DefaultVideoFPS: integer read GetDefaultVideoFPS
      write SetDefaultVideoFPS;
    class property PlayVolume: byte read GetPlayVolume write SetPlayVolume;
    class procedure Save;
    class procedure Cancel;
  end;

implementation

uses
  System.Classes,
  System.Types,
  System.SysUtils,
  System.IOUtils,
  Olf.RTL.Params,
  Olf.RTL.CryptDecrypt;

procedure InitConfig;
begin
  tparams.InitDefaultFileNameV2('OlfSoftware', 'VideoSplitter', false);
{$IFDEF RELEASE }
  tparams.onCryptProc := function(Const AParams: string): TStream
    var
      Keys: TByteDynArray;
      ParStream: TStringStream;
    begin
      ParStream := TStringStream.Create(AParams);
      try
{$I '..\_PRIVATE\src\ConfigFileXORKey.inc'}
        result := TOlfCryptDecrypt.XORCrypt(ParStream, Keys);
      finally
        ParStream.free;
      end;
    end;
  tparams.onDecryptProc := function(Const AStream: TStream): string
    var
      Keys: TByteDynArray;
      Stream: TStream;
      StringStream: TStringStream;
    begin
{$I '..\_PRIVATE\src\ConfigFileXORKey.inc'}
      result := '';
      Stream := TOlfCryptDecrypt.XORdeCrypt(AStream, Keys);
      try
        if assigned(Stream) and (Stream.Size > 0) then
        begin
          StringStream := TStringStream.Create;
          try
            Stream.Position := 0;
            StringStream.CopyFrom(Stream);
            result := StringStream.DataString;
          finally
            StringStream.free;
          end;
        end;
      finally
        Stream.free;
      end;
    end;
{$ENDIF}
  tparams.Load;
end;

{ TConfig }

class procedure TConfig.Cancel;
begin
  tparams.Cancel;
end;

class function TConfig.GetDefaultExportFolder: string;
begin
  result := tparams.getValue('DEF', tpath.GetMoviesPath);
end;

class function TConfig.GetDefaultProjectFolder: string;
begin
  result := tparams.getValue('DPF', tpath.GetMoviesPath);
end;

class function TConfig.GetDefaultSourceVideoFolder: string;
begin
  result := tparams.getValue('DSVF', tpath.GetMoviesPath);
end;

class function TConfig.GetDefaultVideoFPS: integer;
begin
  result := tparams.getValue('DFPS', 30);
end;

class function TConfig.GetFFmpegPath: string;
begin
  result := tparams.getValue('FFmpeg', '');
end;

class function TConfig.GetPlayVolume: byte;
begin
  result := tparams.getValue('Vol', 100);
end;

class procedure TConfig.Save;
begin
  tparams.Save;
end;

class procedure TConfig.SetDefaultExportFolder(const Value: string);
begin
  tparams.setValue('DEF', Value);
end;

class procedure TConfig.SetDefaultProjectFolder(const Value: string);
begin
  tparams.setValue('DPF', Value);
end;

class procedure TConfig.SetDefaultSourceVideoFolder(const Value: string);
begin
  tparams.setValue('DSVF', Value);
end;

class procedure TConfig.SetDefaultVideoFPS(const Value: integer);
begin
  tparams.setValue('DFPS', Value);
end;

class procedure TConfig.SetFFmpegPath(const Value: string);
begin
  tparams.setValue('FFmpeg', Value);
end;

class procedure TConfig.SetPlayVolume(const Value: byte);
begin
  tparams.setValue('Vol', Value);
end;

initialization

InitConfig;

finalization

end.
