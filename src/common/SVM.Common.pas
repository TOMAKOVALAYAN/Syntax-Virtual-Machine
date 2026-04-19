unit SVM.Common;

interface

uses
  System.SysUtils;

const
  // SVM File Signature (Magic Number)
  // Byte values: 'a', 'm', 'i', 'n', 'o', 'g', 'l', 'u'
  SVM_MAGIC: array[0..7] of Byte = (97, 109, 105, 110, 111, 103, 108, 117);

  // Version Information
  SVM_VER_MAJOR = 1;
  SVM_VER_MINOR = 0;

type
  { SVM Operation Codes (Opcodes) }
  TSVMOpcode = (
    // --- Basic and Stack Operations ($00 - $0D) ---
    opNOP     = $00,  // No Operation
    opPUSH_I  = $01,  // Push integer (Int64) onto stack
    opPUSH_F  = $02,  // Push floating point (Double) onto stack
    opPUSH_S  = $03,  // Push text (String) onto stack
    opPOP     = $04,  // Pop value from the top of the stack
    opPRINT   = $09,  // Print value on stack to console
    opDUP     = $0D,  // Duplicate the value at the top of the stack

    // --- Arithmetic Operations ($05 - $08, $1A - $1B) ---
    opADD     = $05,  // Addition
    opSUB     = $06,  // Subtraction
    opMUL     = $07,  // Multiplication
    opDIV     = $08,  // Division
    opMOD     = $1A,  // Modulus (Remainder)
    opPOW     = $1B,  // Power (Exponentiation)

    // --- Comparison Operations ($0E - $13) ---
    opEQ      = $0E,  // Is equal? (==)
    opNEQ     = $0F,  // Is not equal? (!=)
    opGT      = $10,  // Is greater than? (>)
    opLT      = $11,  // Is less than? (<)
    opGTE     = $12,  // Is greater than or equal? (>=)
    opLTE     = $13,  // Is less than or equal? (<=)

    // --- Flow Control ($0A - $17, $FF) ---
    opJMP     = $0A,  // Unconditional Jump
    opJZ      = $0B,  // Jump if Zero
    opJNZ     = $0C,  // Jump if Not Zero
    opCALL    = $16,  // Call function
    opRET     = $17,  // Return from function
    opHALT    = $FF,  // Stop program

    // --- Memory Management (Global & Local) ($14 - $51) ---
    opSTORE   = $14,  // Store to global variable
    opLOAD    = $15,  // Load from global variable
    opSTORE_L = $18,  // Store to local variable (Stack Frame)
    opLOAD_L  = $19,  // Load from local variable
    opENTER   = $50,  // Create Local Frame
    opLEAVE   = $51,  // Close Local Frame

    // --- Logical Operators ($30 - $32) ---
    opAND     = $30,  // Logical AND
    opOR      = $31,  // Logical OR
    opNOT     = $32,  // Logical NOT

    // --- Type Casting and Input ($52 - $54) ---
    opCAST_I  = $52,  // Float -> Int
    opCAST_F  = $53,  // Int -> Float
    opINPUT   = $54,  // Get data from user

    // --- Dynamic Memory (Heap) & Array Operations ($20 - $24) ---
    opALLOC   = $20,  // Allocate memory from Heap
    opSSET    = $21,  // Set value in Heap
    opSGET    = $22,  // Get value from Heap
    opFREE    = $23,  // Free memory
    opLEN     = $24,  // Get block size

    // --- String Manipulation ($40 - $41) ---
    opCONCAT  = $40,  // Concatenate strings
    opSTRLEN  = $41,  // String length

    // --- Native Bridge (DLL) Operations ($60 - $62) ---
    opDLL_LOAD = $60, // Load DLL file into memory
    opDLL_CALL = $61, // Call function within DLL
    opDLL_FREE = $62  // Unload DLL from memory
  );

// Helper function for debug and error messages
function OpcodeToString(Op: TSVMOpcode): string;

implementation

function OpcodeToString(Op: TSVMOpcode): string;
begin
  case Op of
    opNOP:      Result := 'NOP';
    opPUSH_I:   Result := 'PUSH_I';
    opPUSH_F:   Result := 'PUSH_F';
    opPUSH_S:   Result := 'PUSH_S';
    opPOP:      Result := 'POP';
    opPRINT:    Result := 'PRINT';
    opDUP:      Result := 'DUP';
    opADD:      Result := 'ADD';
    opSUB:      Result := 'SUB';
    opMUL:      Result := 'MUL';
    opDIV:      Result := 'DIV';
    opMOD:      Result := 'MOD';
    opPOW:      Result := 'POW';
    opEQ:       Result := 'EQ';
    opNEQ:      Result := 'NEQ';
    opGT:       Result := 'GT';
    opLT:       Result := 'LT';
    opGTE:      Result := 'GTE';
    opLTE:      Result := 'LTE';
    opJMP:      Result := 'JMP';
    opJZ:       Result := 'JZ';
    opJNZ:      Result := 'JNZ';
    opCALL:     Result := 'CALL';
    opRET:      Result := 'RET';
    opHALT:     Result := 'HALT';
    opSTORE:    Result := 'STORE';
    opLOAD:     Result := 'LOAD';
    opSTORE_L:  Result := 'STORE_L';
    opLOAD_L:   Result := 'LOAD_L';
    opENTER:    Result := 'ENTER';
    opLEAVE:    Result := 'LEAVE';
    opAND:      Result := 'AND';
    opOR:       Result := 'OR';
    opNOT:      Result := 'NOT';
    opCAST_I:   Result := 'CAST_I';
    opCAST_F:   Result := 'CAST_F';
    opINPUT:    Result := 'INPUT';
    opALLOC:    Result := 'ALLOC';
    opSSET:     Result := 'SSET';
    opSGET:     Result := 'SGET';
    opFREE:     Result := 'FREE';
    opLEN:      Result := 'LEN';
    opCONCAT:   Result := 'CONCAT';
    opSTRLEN:   Result := 'STRLEN';
    opDLL_LOAD: Result := 'DLL_LOAD';
    opDLL_CALL: Result := 'DLL_CALL';
    opDLL_FREE: Result := 'DLL_FREE';
    else        Result := 'UNKNOWN_OP ($' + IntToHex(Byte(Op), 2) + ')';
  end;
end;

end.
