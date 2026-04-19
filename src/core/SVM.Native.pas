unit SVM.Native;

interface

uses
  System.SysUtils, Winapi.Windows, System.Generics.Collections, SVM.Types, SVM.Common;

type
  { Parameter types for DLL function calls }
  TNativeArgType = (atInt, atFloat, atString, atPtr);

  TSVMNativeBridge = class
  private
    FLibraries: TDictionary<string, THandle>;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadLib(const ALibName: string): THandle;
    procedure FreeLib(AHandle: THandle);

    {
      Dynamic Function Call:
      - AHandle: DLL Handle
      - AFuncName: Function Name
      - AArgs: Parameters coming from the SVM stack
    }
    function CallFunc(AHandle: THandle; const AFuncName: string; const AArgs: array of TSVMCell): TSVMCell;
  end;

implementation

constructor TSVMNativeBridge.Create;
begin
  FLibraries := TDictionary<string, THandle>.Create;
end;

destructor TSVMNativeBridge.Destroy;
var
  Lib: THandle;
begin
  for Lib in FLibraries.Values do
    FreeLibrary(Lib);
  FLibraries.Free;
  inherited;
end;

function TSVMNativeBridge.LoadLib(const ALibName: string): THandle;
begin
  if not FLibraries.TryGetValue(ALibName.ToLower, Result) then
  begin
    Result := LoadLibrary(PChar(ALibName));
    if Result = 0 then
      raise Exception.Create(Format('Could not load DLL: %s (Error Code: %d)', [ALibName, GetLastError]));
    FLibraries.Add(ALibName.ToLower, Result);
  end;
end;

procedure TSVMNativeBridge.FreeLib(AHandle: THandle);
var
  Pair: TPair<string, THandle>;
  TargetKey: string;
begin
  TargetKey := '';
  for Pair in FLibraries do
    if Pair.Value = AHandle then
    begin
      TargetKey := Pair.Key;
      Break;
    end;

  if TargetKey <> '' then
  begin
    FreeLibrary(AHandle);
    FLibraries.Remove(TargetKey);
  end;
end;

function TSVMNativeBridge.CallFunc(AHandle: THandle; const AFuncName: string; const AArgs: array of TSVMCell): TSVMCell;
var
  FuncPtr: Pointer;
  ArgList: array of NativeUInt;
  I: Integer;
  ResInt: NativeUInt;
  ArgLen: Integer;
  ArgDataPtr: Pointer;
begin
  FuncPtr := GetProcAddress(AHandle, PChar(AFuncName));
  if FuncPtr = nil then
    raise Exception.Create('DLL Function not found: ' + AFuncName);

  ArgLen := Length(AArgs);
  SetLength(ArgList, ArgLen);

  // 1. Prepare Arguments (Marshalling)
  for I := 0 to High(AArgs) do
  begin
    case AArgs[I].vType of
      vtInt:    ArgList[I] := NativeUInt(AArgs[I].i);
      vtFloat:  ArgList[I] := NativeUInt(Trunc(AArgs[I].f));
      vtString: ArgList[I] := NativeUInt(AArgs[I].s);
      vtAddr:   ArgList[I] := NativeUInt(AArgs[I].addr);
      else      ArgList[I] := 0;
    end;
  end;

  // Get the address where the actual array data starts
  if ArgLen > 0 then
    ArgDataPtr := @ArgList[0]
  else
    ArgDataPtr := nil;

  try
    {$IFDEF CPUX86}
    asm
      push ebx
      push esi

      mov esi, ArgDataPtr  // Start address of ArgList data
      mov ecx, ArgLen      // Number of arguments
      test ecx, ecx
      jz @no_args

      // For Windows stdcall, parameters must be pushed from right to left (reverse).
      // Move ESI to the last element.
      mov eax, ecx
      dec eax
      shl eax, 2           // eax = (ArgLen - 1) * 4
      add esi, eax         // ESI is now at the last parameter

    @loop_args:
      push dword ptr [esi]
      sub esi, 4           // Move to the previous parameter
      dec ecx
      jnz @loop_args

    @no_args:
      call FuncPtr
      mov ResInt, eax      // Store the return value

      pop esi
      pop ebx
    end;
    {$ENDIF}

    {$IFDEF CPUX64}
    // Note: In x64, parameters are passed via RCX, RDX, R8, R9 registers.
    // It is recommended to use TValue.Invoke (RTTI) instead of inline assembly for x64.
    raise Exception.Create('x64 Native Bridge is currently not supported. Please use Win32.');
    {$ENDIF}

    Result := TSVMCell.CreateInt(ResInt);

  except
    on E: Exception do
      raise Exception.Create('Native Call Error: ' + E.Message);
  end;
end;

end.
