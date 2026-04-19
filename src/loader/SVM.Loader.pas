unit SVM.Loader;

interface

uses
  System.SysUtils,
  System.Classes,
  SVM.Common,
  SVM.CPU,
  SVM.Strings; // Added for String Pool support

type
  TSVMLoader = class
  public
    // Parameter count increased to 3: FileName, ACPU, and AStrings
    class procedure LoadIntoCPU(const FileName: string; ACPU: TSVMCPU; AStrings: TSVMStringPool);
  end;

implementation

class procedure TSVMLoader.LoadIntoCPU(const FileName: string; ACPU: TSVMCPU; AStrings: TSVMStringPool);
var
  FS: TFileStream;
  Magic: array[0..7] of Byte;
  VerMajor, VerMinor: Byte;
  CodeSize: Integer;
  ByteCode: array of Byte;
begin
  if not FileExists(FileName) then
    raise Exception.Create('SVM Loader: File not found -> ' + FileName);

  FS := TFileStream.Create(FileName, fmOpenRead);
  try
    // 1. Signature Check
    FS.ReadBuffer(Magic, 8);
    if not CompareMem(@Magic, @SVM_MAGIC, 8) then
      raise Exception.Create('SVM Loader: Invalid file signature!');

    // 2. Version Information
    FS.ReadBuffer(VerMajor, 1);
    FS.ReadBuffer(VerMinor, 1);

    // 3. Read Code (All remaining bytes are considered bytecode)
    CodeSize := FS.Size - FS.Position;
    if CodeSize > 0 then
    begin
      SetLength(ByteCode, CodeSize);
      FS.ReadBuffer(ByteCode[0], CodeSize);

      // Load bytecode into CPU
      ACPU.LoadCode(ByteCode);
    end;

    // Note: AStrings will be used here if you decide to load a pre-compiled
    // String Pool from the file in the future.

    Writeln(Format('SVM Loader: %d bytes loaded (Virtual Machine v%d.%d)', [CodeSize, VerMajor, VerMinor]));
  finally
    FS.Free;
  end;
end;

end.
