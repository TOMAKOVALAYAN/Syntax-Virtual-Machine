program SVM;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  System.IOUtils,
  { Project Units }
  SVM.Common in 'src\common\SVM.Common.pas',
  SVM.Types in 'src\common\SVM.Types.pas',
  SVM.Memory in 'src\core\SVM.Memory.pas',
  SVM.CPU in 'src\core\SVM.CPU.pas',
  SVM.Strings in 'src\core\SVM.Strings.pas',
  SVM.Loader in 'src\loader\SVM.Loader.pas',
  SVM.Assembler in 'src\compiler\SVM.Assembler.pas',
  SVM.Native in 'src\core\SVM.Native.pas';

var
  SVMMemory: TSVMMemory;
  SVMCPU: TSVMCPU;
  Mode, TargetFile, OutFile: string;
  CompiledBytes: TBytes;

procedure ShowHeader;
begin
  Writeln('=======================================================');
  Writeln('         SYNTAX VIRTUAL MACHINE (SVM) ');
  Writeln('=======================================================');
end;

procedure ShowUsage;
begin
  Writeln('Usage:');
  Writeln('  SVM build <main_file.syasm>    -> Compiles the project (.syprg)');
  Writeln('  SVM run   <program.syprg>      -> Runs the Program');
  Writeln('  SVM debug <program.syprg>      -> Debug step by step');
  Writeln('');
end;

procedure SetColor(Color: Word);
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Color);
end;

begin
  { Set console output and input encoding to UTF-8 }
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);

  { Parameter check }
  if ParamCount < 2 then
  begin
    ShowHeader;
    ShowUsage;
    Exit;
  end;

  Mode := ParamStr(1).ToLower;
  TargetFile := ParamStr(2);

  try
    { --- BUILD MODE --- }
    if Mode = 'build' then
    begin
      ShowHeader;
      Writeln('SVM-Linker: Scanning "' + TargetFile + '" and dependencies...');

      // Recursively resolve IMPORT statements and generate Bytecode
      CompiledBytes := TSVMAssembler.BuildProject(TargetFile);

      OutFile := ChangeFileExt(TargetFile, '.syprg');
      var BinaryFile := TFileStream.Create(OutFile, fmCreate);
      try
        // Write SVM Header (Magic Number: 'aminoglu')
        BinaryFile.WriteBuffer(SVM_MAGIC, 8);

        // Write Version Information
        var V: Byte := SVM_VER_MAJOR; BinaryFile.Write(V, 1);
        V := SVM_VER_MINOR; BinaryFile.Write(V, 1);

        // Write Compiled Bytecode
        if Length(CompiledBytes) > 0 then
          BinaryFile.WriteBuffer(CompiledBytes[0], Length(CompiledBytes));
      finally
        BinaryFile.Free;
      end;

      SetColor(FOREGROUND_GREEN or FOREGROUND_INTENSITY);
      Writeln(Format('Success! %d bytes of bytecode have been written into: %s', [Length(CompiledBytes), OutFile]));
      SetColor(7);
    end

    { --- RUN OR DEBUG MODE --- }
    else if (Mode = 'run') or (Mode = 'debug') then
    begin
      if not TFile.Exists(TargetFile) then
        raise Exception.Create('No executable file found: ' + TargetFile);

      SVMMemory := TSVMMemory.Create;
      // Native Bridge is now automatically created within SVMCPU (SVM.CPU.pas)
      SVMCPU := TSVMCPU.Create(SVMMemory);
      try
        // Set Debug mode
        SVMCPU.DebugMode := (Mode = 'debug');

        // Verify binary file with Loader and load into CPU memory
        TSVMLoader.LoadIntoCPU(TargetFile, SVMCPU, SVMCPU.Strings);

        if Mode = 'run' then
          Writeln('--- SVM EXECUTION START ---' + sLineBreak)
        else
          Writeln('--- SVM DEBUG MODE ACTIVE ---' + sLineBreak);

        // Fire the virtual processor!
        SVMCPU.Run;

        Writeln(sLineBreak + '--- PROGRAM TERMINATED ---');
      finally
        SVMCPU.Free;
        SVMMemory.Free;
      end;
    end
    else
    begin
      Writeln('Unknown Command: ' + Mode);
      ShowUsage;
    end;

  except
    on E: Exception do
    begin
      SetColor(FOREGROUND_RED or FOREGROUND_INTENSITY);
      Writeln(sLineBreak + '!!! SVM ERROR !!!');
      Writeln('Error Type: ', E.ClassName);
      Writeln('Message: ', E.Message);
      SetColor(7);
    end;
  end;

  // Prevent console window from closing immediately in debug or error states
  if (Mode = 'debug') or (ParamCount = 0) then
  begin
    Writeln(sLineBreak + 'Press Enter To Exit...');
    Readln;
  end;
end.
