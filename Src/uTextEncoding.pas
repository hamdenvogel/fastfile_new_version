unit uTextEncoding;

{
  Helpers para texto UTF-8 / Unicode em Delphi 7 (ANSI VCL).
  - MessageBoxW e conversao UTF-8 -> WideString -> CP_ACP para exibicao.
  - Deteccao heuristica UTF-8 sem BOM.

  IMPORTANTE: DisplayTextFromFileBytes mantem a logica historica (bytes crus como string
  nos fallbacks). Copiar para a clipboard usa o mesmo texto exibido (GetLineContent) +
  ClipboardSetUnicodeText (CF_UNICODETEXT).
}

interface

uses
  Windows, SysUtils;

{ Converte octetos UTF-8 (AnsiString) para WideString. }
function Utf8AnsiToWideString(const Utf8: AnsiString): WideString;

{ WideString -> string ANSI da code page do Windows (para Caption, ListView, etc.). }
function WideStringToAnsiACP(const W: WideString): AnsiString;

{ Linha lida como bytes brutos: aplica conversao conforme encoding de EXIBICAO (UTF-8, ANSI, UTF-16...). }
function DisplayTextFromFileBytes(const Raw: AnsiString; const DisplayEncoding: string): string;

{ Coloca texto Unicode na area de transferencia (CF_UNICODETEXT). Evita corrupcao de acentos vs Clipboard.AsText no D7. }
procedure ClipboardSetUnicodeText(const W: WideString);

{ True se o buffer contem sequencias UTF-8 validas com pelo menos um caractere nao-ASCII. }
function IsProbablyUtf8(const S: AnsiString): Boolean;

implementation

uses
  Forms,
  ClipBrd;

function Utf8AnsiToWideString(const Utf8: AnsiString): WideString;
var
  Len: Integer;
begin
  Result := '';
  if Utf8 = '' then Exit;
  Len := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Utf8), Length(Utf8), nil, 0);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Utf8), Length(Utf8), PWideChar(Result), Len);
end;

function WideStringToAnsiACP(const W: WideString): AnsiString;
var
  Len: Integer;
begin
  Result := '';
  if W = '' then Exit;
  Len := WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  if Len <= 0 then Exit;
  SetLength(Result, Len);
  WideCharToMultiByte(CP_ACP, 0, PWideChar(W), Length(W), PAnsiChar(Result), Len, nil, nil);
end;

function Utf16LEToWideString(const Raw: AnsiString): WideString;
var
  n, i: Integer;
begin
  Result := '';
  if Raw = '' then Exit;
  n := Length(Raw) div 2;
  if n <= 0 then Exit;
  SetLength(Result, n);
  for i := 1 to n do
    Result[i] := WideChar(Word(Ord(Raw[2 * i - 1])) or (Word(Ord(Raw[2 * i])) shl 8));
end;

function Utf16BEToWideString(const Raw: AnsiString): WideString;
var
  n, i: Integer;
begin
  Result := '';
  if Raw = '' then Exit;
  n := Length(Raw) div 2;
  if n <= 0 then Exit;
  SetLength(Result, n);
  for i := 1 to n do
    Result[i] := WideChar((Word(Ord(Raw[2 * i - 1])) shl 8) or Word(Ord(Raw[2 * i])));
end;

function DisplayTextFromFileBytes(const Raw: AnsiString; const DisplayEncoding: string): string;
var
  U: string;
  W: WideString;
begin
  if Raw = '' then
  begin
    Result := '';
    Exit;
  end;
  { Logica original (nao delegar a DisplayWideString): evita round-trip CP_ACP em modo
    "ANSI/cru" e preserva fallbacks string(Raw) identicos ao comportamento anterior. }
  U := UpperCase(DisplayEncoding);
  if Pos('UTF-16', U) > 0 then
  begin
    if (Pos('UTF-16 BE', U) > 0) or (Pos('UTF16 BE', U) > 0) then
      W := Utf16BEToWideString(Raw)
    else
      W := Utf16LEToWideString(Raw);
    if W <> '' then
      Result := string(WideStringToAnsiACP(W))
    else
      Result := string(Raw);
    Exit;
  end;
  if (Pos('UTF-8', U) > 0) or (Pos('UTF8', U) > 0) then
  begin
    W := Utf8AnsiToWideString(Raw);
    if W <> '' then
      Result := string(WideStringToAnsiACP(W))
    else
      Result := string(Raw);
    Exit;
  end;
  { ANSI, OEM, ou "raw" — octetos como texto (igual ao historico) }
  Result := string(Raw);
end;

procedure ClipboardSetUnicodeText(const W: WideString);
var
  hMem: HGLOBAL;
  P: Pointer;
  N: Integer;
  HWin: HWND;
  Ok: Boolean;
begin
  N := (Length(W) + 1) * SizeOf(WideChar);
  if N < Integer(SizeOf(WideChar)) then Exit;
  hMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, N);
  if hMem = 0 then Exit;
  P := GlobalLock(hMem);
  if P = nil then
  begin
    GlobalFree(hMem);
    Exit;
  end;
  try
    FillChar(P^, N, 0);
    if Length(W) > 0 then
      Move(PWideChar(W)^, P^, Length(W) * SizeOf(WideChar));
  finally
    GlobalUnlock(hMem);
  end;

  HWin := 0;
  if Assigned(Application) and (Application.Handle <> 0) then
    HWin := Application.Handle;

  Ok := OpenClipboard(HWin);
  if not Ok then
    Ok := OpenClipboard(0);

  if not Ok then
  begin
    GlobalFree(hMem);
    try
      Clipboard.AsText := string(WideStringToAnsiACP(W));
    except
    end;
    Exit;
  end;
  try
    EmptyClipboard;
    if SetClipboardData(CF_UNICODETEXT, hMem) <> 0 then
      hMem := 0
    else
    begin
      GlobalFree(hMem);
      try
        Clipboard.AsText := string(WideStringToAnsiACP(W));
      except
      end;
    end;
  finally
    CloseClipboard;
  end;
end;

function IsProbablyUtf8(const S: AnsiString): Boolean;
var
  i, L, b: Integer;
  Need: Integer;
begin
  Result := False;
  L := Length(S);
  i := 1;
  while i <= L do
  begin
    b := Ord(S[i]);
    if b < $80 then
    begin
      Inc(i);
      Continue;
    end;
    { 110xxxxx 10xxxxxx }
    if (b and $E0) = $C0 then
    begin
      Need := 1;
      if (b and $FE) = $C0 then Exit;
    end
    else if (b and $F0) = $E0 then
      Need := 2
    else if (b and $F8) = $F0 then
      Need := 3
    else
      Exit;
    if i + Need > L then Exit;
    while Need > 0 do
    begin
      Inc(i);
      if (Ord(S[i]) and $C0) <> $80 then Exit;
      Dec(Need);
    end;
    Inc(i);
    Result := True;
  end;
end;

end.
