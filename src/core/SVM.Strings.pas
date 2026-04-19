unit SVM.Strings;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TSVMStringPool = class
  private
    { Generic list to manage PChar addresses }
    FStrings: TList<PChar>;
  public
    constructor Create;
    destructor Destroy; override;

    { Creates a new string, adds it to the pool, and returns its address (PChar) }
    function Intern(const Value: string): PChar;

    { Safely combines two PChars and interns the result into the pool }
    function Combine(S1, S2: PChar): PChar;

    { Releases all string memory }
    procedure Clear;
  end;

implementation

constructor TSVMStringPool.Create;
begin
  inherited Create;
  FStrings := TList<PChar>.Create;
end;

destructor TSVMStringPool.Destroy;
begin
  Clear;
  FStrings.Free;
  inherited;
end;

function TSVMStringPool.Intern(const Value: string): PChar;
var
  P: PChar;
  Len: Integer;
begin
  if Value = '' then Exit(nil);

  {
    Manual management to prevent memory corruption:
    String length + 1 (for Null Terminator #0)
  }
  Len := (Length(Value) + 1) * SizeOf(Char);

  { Allocate memory }
  GetMem(P, Len);

  {
    CRITICAL: Completely zero out the memory.
    This clears remnants of previous data to ensure a clean string.
  }
  FillChar(P^, Len, 0);

  { Copy the string content into the allocated memory }
  if Length(Value) > 0 then
    Move(Pointer(Value)^, P^, Length(Value) * SizeOf(Char));

  FStrings.Add(P);
  Result := P;
end;

function TSVMStringPool.Combine(S1, S2: PChar): PChar;
var
  CombinedStr: string;
begin
  { Safely convert PChars to Delphi strings and concatenate them }
  CombinedStr := StrPas(S1) + StrPas(S2);

  { Intern the newly formed string to include it in the pool }
  Result := Intern(CombinedStr);
end;

procedure TSVMStringPool.Clear;
var
  P: PChar;
begin
  { Free memory allocated with GetMem for all PChars in the list }
  for P in FStrings do
  begin
    if P <> nil then
      FreeMem(P);
  end;
  FStrings.Clear;
end;

end.
