unit SVM.Memory;

interface

uses
  System.SysUtils,
  SVM.Common,
  SVM.Types;

const
  // Metadata Header Structure
  // [Address - 2]: Block Size
  // [Address - 1]: Block Status (Flags - 0: Dead, 1: Alive)
  HDR_SIZE = 2;
  FLAG_DEAD = 0;
  FLAG_ALIVE = 1;
  STACK_SIZE = 4096; // Increased stack size

type
  TSVMMemory = class
  private
    // Data Stack
    FStack: array[0..STACK_SIZE] of TSVMCell;
    FSP: Integer; // Stack Pointer
    FBP: Integer; // Base Pointer (Start of Stack Frame)

    // Global Variables (Static Memory)
    FVariables: array[0..255] of TSVMCell;

    // Call Stack
    FCallStack: array[0..511] of Integer;
    FCSP: Integer;

    // --- HEAP MEMORY ---
    FHeap: array of TSVMCell;
    FHeapPtr: Integer;

  public
    constructor Create;

    // --- Data Stack Operations ---
    procedure Push(const Value: TSVMCell);
    function Pop: TSVMCell;
    function Peek: TSVMCell;
    function IsEmpty: Boolean;
    function GetAt(Index: Integer): TSVMCell;

    // --- Global Variable Operations ---
    procedure Store(const Index: Byte; const Value: TSVMCell);
    function Load(const Index: Byte): TSVMCell;

    // --- Local Variable & Parameter Operations ---
    procedure StoreLocal(const Index: Integer; const Value: TSVMCell);
    function LoadLocal(const Index: Integer): TSVMCell;

    // --- Call Stack Operations ---
    procedure CallPush(const AValue: Integer);
    function CallPop: Integer;

    // --- SAFE HEAP OPERATIONS ---
    function Allocate(const ASize: Integer): Integer;
    procedure HeapStore(const AAddr: Integer; const AValue: TSVMCell);
    function HeapLoad(const AAddr: Integer): TSVMCell;
    procedure Deallocate(const AAddr: Integer);
    function GetBlockSize(const AAddr: Integer): Integer;

    // Properties
    property SP: Integer read FSP write FSP;
    property BP: Integer read FBP write FBP;
    property CSP: Integer read FCSP;
    property HeapPtr: Integer read FHeapPtr;
  end;

implementation

constructor TSVMMemory.Create;
var
  I: Integer;
begin
  inherited Create;
  FSP := 0;
  FBP := 0;
  FCSP := -1;
  FHeapPtr := HDR_SIZE;

  SetLength(FHeap, 2048);

  // Clear memory areas (Reset)
  for I := 0 to High(FVariables) do FVariables[I] := TSVMCell.CreateInt(0);
  for I := 0 to High(FStack) do FStack[I] := TSVMCell.CreateInt(0);
end;

{ --- Data Stack --- }

procedure TSVMMemory.Push(const Value: TSVMCell);
begin
  if FSP >= High(FStack) then
    raise Exception.Create('SVM Error: Stack Overflow');
  FStack[FSP] := Value;
  Inc(FSP);
end;

function TSVMMemory.Pop: TSVMCell;
begin
  if FSP <= 0 then
    raise Exception.Create('SVM Error: Stack Underflow');
  Dec(FSP);
  Result := FStack[FSP];
end;

function TSVMMemory.Peek: TSVMCell;
begin
  if FSP <= 0 then
    raise Exception.Create('SVM Error: Stack Underflow (Peek)');
  Result := FStack[FSP - 1];
end;

function TSVMMemory.IsEmpty: Boolean;
begin
  Result := FSP = 0;
end;

function TSVMMemory.GetAt(Index: Integer): TSVMCell;
begin
  if (Index < 0) or (Index >= FSP) then
    raise Exception.CreateFmt('SVM Error: Invalid stack access (Index: %d)', [Index]);
  Result := FStack[Index];
end;

{ --- Global Variables --- }

procedure TSVMMemory.Store(const Index: Byte; const Value: TSVMCell);
begin
  FVariables[Index] := Value;
end;

function TSVMMemory.Load(const Index: Byte): TSVMCell;
begin
  Result := FVariables[Index];
end;

{ --- Local Variables (Stack Frame) --- }

procedure TSVMMemory.StoreLocal(const Index: Integer; const Value: TSVMCell);
var
  TargetIdx: Integer;
begin
  // TargetIdx = BasePointer + Offset
  // If offset is negative, it accesses parameters; if positive, it accesses local variables
  TargetIdx := FBP + Index;

  if (TargetIdx < 0) or (TargetIdx >= STACK_SIZE) then
    raise Exception.CreateFmt('SVM Error: Local memory boundary violation (StoreLocal). Address: %d, BP: %d', [TargetIdx, FBP]);

  FStack[TargetIdx] := Value;
end;

function TSVMMemory.LoadLocal(const Index: Integer): TSVMCell;
var
  TargetIdx: Integer;
begin
  TargetIdx := FBP + Index;

  if (TargetIdx < 0) or (TargetIdx >= STACK_SIZE) then
    raise Exception.CreateFmt('SVM Error: Local memory limit violation (LoadLocal). Address: %d, BP: %d', [TargetIdx, FBP]);

  Result := FStack[TargetIdx];
end;

{ --- Call Stack --- }

procedure TSVMMemory.CallPush(const AValue: Integer);
begin
  if FCSP >= High(FCallStack) then
    raise Exception.Create('SVM Error: Call Stack Overflow');
  Inc(FCSP);
  FCallStack[FCSP] := AValue;
end;

function TSVMMemory.CallPop: Integer;
begin
  if FCSP < 0 then
    raise Exception.Create('SVM Error: Call Stack Underflow');
  Result := FCallStack[FCSP];
  Dec(FCSP);
end;

{ --- SAFE HEAP & ARRAY OPERATIONS --- }

function TSVMMemory.Allocate(const ASize: Integer): Integer;
begin
  if ASize <= 0 then
    raise Exception.Create('SVM Error: Invalid memory allocation size.');

  Result := FHeapPtr + HDR_SIZE;

  // Expand heap if full
  if (Result + ASize) >= Length(FHeap) then
    SetLength(FHeap, Length(FHeap) + 1024 + ASize);

  // Write Metadata (Header)
  FHeap[Result - 2] := TSVMCell.CreateInt(ASize);
  FHeap[Result - 1] := TSVMCell.CreateInt(FLAG_ALIVE);

  FHeapPtr := Result + ASize;
end;

procedure TSVMMemory.HeapStore(const AAddr: Integer; const AValue: TSVMCell);
begin
  if (AAddr < HDR_SIZE) or (AAddr >= Length(FHeap)) then
    raise Exception.CreateFmt('SVM Error: Heap Write Boundary Violation! Address: %d', [AAddr]);

  FHeap[AAddr] := AValue;
end;

function TSVMMemory.HeapLoad(const AAddr: Integer): TSVMCell;
begin
  if (AAddr < HDR_SIZE) or (AAddr >= Length(FHeap)) then
    raise Exception.CreateFmt('SVM Error: Heap Read Boundary Violation! Address: %d', [AAddr]);

  Result := FHeap[AAddr];
end;

function TSVMMemory.GetBlockSize(const AAddr: Integer): Integer;
begin
  if (AAddr < HDR_SIZE) or (AAddr - 2 < 0) then Exit(0);
  Result := FHeap[AAddr - 2].i;
end;

procedure TSVMMemory.Deallocate(const AAddr: Integer);
begin
  if (AAddr < HDR_SIZE) or (AAddr >= Length(FHeap)) then
    raise Exception.Create('SVM Error: Invalid address cannot be released.');

  FHeap[AAddr - 1] := TSVMCell.CreateInt(FLAG_DEAD);
end;

end.
