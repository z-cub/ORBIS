{ ****************************************************************************** }
{ }
{ Library:          Fundamentals 4.00 }
{ File name:        cRandom.pas }
{ File version:     4.16 }
{ Description:      Random number functions }
{ }
{ Copyright:        Copyright (c) 1999-2015, David J Butler }
{ All rights reserved. }
{ Redistribution and use in source and binary forms, with }
{ or without modification, are permitted provided that }
{ the following conditions are met: }
{ Redistributions of source code must retain the above }
{ copyright notice, this list of conditions and the }
{ following disclaimer. }
{ THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND }
{ CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED }
{ WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED }
{ WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A }
{ PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL }
{ THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, }
{ INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR }
{ CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, }
{ PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF }
{ USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) }
{ HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER }
{ IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING }
{ NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE }
{ USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE }
{ POSSIBILITY OF SUCH DAMAGE. }
{ }
{ Github:           https://github.com/fundamentalslib }
{ E-mail:           fundamentalslib at gmail.com }
{ }
{ Revision history: }
{ }
{ 1999/11/07  0.01  Add RandomSeed. }
{ 1999/12/01  0.02  Add RandomUniform. }
{ 1999/12/03  0.03  Add RandomNormal. }
{ 2000/01/23  1.04  Add RandomPseudoWord. }
{ 2000/07/13  1.05  Fix bug reported by Andrew Driazgov. }
{ 2000/08/22  1.06  Add RandomHex. }
{ 2000/09/20  1.07  Improve RandomSeed. }
{ 2002/06/01  3.08  Create cRandom unit. }
{ 2003/08/09  3.09  Replace random number generator. }
{ 2005/06/10  4.10  Compilable with FreePascal 2 Win32 i386. }
{ 2005/08/27  4.11  Revised for Fundamentals 4. }
{ 2007/06/08  4.12  Compilable with FreePascal 2.04 Win32 i386 }
{ 2010/06/27  4.13  Compilable with FreePascal 2.4.0 OSX x86-64 }
{ 2015/04/19  4.14  Changes for 64-bit compilers and RawByteString }
{ 2015/04/20  4.15  Revise RandomSeed }
{ 2015/05/06  4.16  Prevent mwcRandom32 overflow error. }
{ }
{ Supported compilers: }
{ }
{ Delphi XE7 Win32                    4.16  2015/05/06 }
{ Delphi XE7 Win64                    4.16  2015/05/06 }
{ }
{ ****************************************************************************** }

unit RSA.cRandom;

interface

{ }
{ RandomSeed }
{ }
{ RandomSeed returns a random seed value based on various system states. }
{ AddEntropy can be called to add additional random state to the values }
{ returned by RandomSeed. }
{ }
procedure AddEntropy(const Value: Int64);
function RandomSeed32: LongWord;

{ }
{ Uniform random number generator }
{ }
{ Returns a random number from a uniform density distribution (ie all }
{ values have an equal probability of being 'chosen') }
{ RandomFloat returns an uniformly distributed random floating point value }
{ between 0 and 1. }
{ RandomAlphaStr returns a string of random letters (A-Z). }
{ RandomPseudoWord returns a random word-like string. }
{ }
procedure SetRandomSeed(const Seed: LongWord);

function RandomUniform32: LongWord;
function RandomUniform(const N: Integer): Integer;
function RandomUniform16: Word;
function RandomByte: Byte;
function RandomByteNonZero: Byte;
function RandomBoolean: Boolean;
function RandomInt64: Int64; overload;
function RandomInt64(const N: Int64): Int64; overload;

function RandomHex(const Digits: Integer; const UpperCase: Boolean = True): String;
// function  RandomHexA(const Digits: Integer; const UpperCase: Boolean = True): RawByteString;
// function  RandomHexW(const Digits: Integer; const UpperCase: Boolean = True): WideString;
function RandomHexU(const Digits: Integer; const UpperCase: Boolean = True): UnicodeString;

function RandomFloat: Extended;

{
  function  RandomUpperAlphaStrA(const Length: Integer): RawByteString;
  function  RandomPseudoWordA(const Length: Integer): RawByteString;
  function  RandomPasswordA(const MinLength, MaxLength: Integer;
  const CaseSensitive, UseSymbols, UseNumbers: Boolean): RawByteString;
}
function RandomPassword(const MinLength, MaxLength: Integer; const CaseSensitive, UseSymbols, UseNumbers: Boolean): String;

{ }
{ Alternative uniform random number generators }
{ }
function mwcRandom32: LongWord;
function urnRandom32: LongWord;
function moaRandomFloat: Extended;
function mwcRandomFloat: Extended;

{ }
{ Normal distribution random number generator }
{ }
{ RandomNormalF returns a random number that has a Normal(0,1) distribution }
{ (Gaussian distribution) }
{ }
function RandomNormalF: Extended;

implementation

uses
  {System}
{$IFDEF DOT_NET}
  Borland.Vcl.Windows,
  System.Threading,
{$ELSE}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$ENDIF}
{$IFDEF UNIX}
{$IFDEF FREEPASCAL}
  BaseUnix,
  Unix,
{$ELSE}
  Libc,
{$ENDIF}
{$ENDIF}
  SysUtils;

{ }
{ Linear Congruential Random Number Generators }
{ The general form of a linear congruential generator is: }
{ SEED = (A * SEED + C) mod M }
{ }
function lcRandom1(const Seed: LongWord): LongWord;
begin
  Result := LongWord(29943829 * Int64(Seed) - 1);
end;

function lcRandom2(const Seed: LongWord): LongWord;
begin
  Result := LongWord(69069 * Int64(Seed) + 1);
end;

function lcRandom3(const Seed: LongWord): LongWord;
begin
  Result := LongWord(1103515245 * Int64(Seed) + 12345);
end;

function lcRandom4(const Seed: LongWord): LongWord;
begin
  Result := LongWord(214013 * Int64(Seed) + 2531011);
end;

function lcRandom5(const Seed: LongWord): LongWord;
begin
  Result := LongWord(134775813 * Int64(Seed) + 1);
end;

{ }
{ System sources of pseudo-randomness }
{ }
{$IFDEF MSWINDOWS}

function GetHighPrecisionCounter: Int64;
begin
  QueryPerformanceCounter(Result);
end;
{$ENDIF}
// {$IFDEF UNIX}
{$IFDEF POSIX}
{$IFDEF FREEPASCAL}

function GetHighPrecisionCounter: Int64;
var
  TV: TTimeVal;
  TZ: PTimeZone;
begin
  TZ := nil;
  fpGetTimeOfDay(@TV, TZ);
  Result := Int64(TV.tv_sec) * 1000000 + Int64(TV.tv_usec);
end;
{$ELSE}

function GetHighPrecisionCounter: Int64;
// var T : Ttimeval;
// var T : TTimeStamp;
var
  T: TDateTime;
begin
  // GetTimeOfDay(T, nil);

  T := GetTime();

  // Result := Int64(T.tv_sec) * 1000000 + Int64(T.tv_usec);
  Result := Int64(Round(T * 1000000)) + Int64(Round(T));
end;
{$ENDIF}
{$ENDIF}
{$IFDEF MSWINDOWS}

function GetTick: LongWord;
begin
  Result := GetTickCount;
end;
{$ELSE}
// {$IFDEF UNIX}
{$IFDEF POSIX}

function GetTick: LongWord;
begin
  Result := LongWord(DateTimeToTimeStamp(Now).Time);
end;
{$ENDIF}
{$ENDIF}

function RandomState: Int64;
var
  H, Mi, S, S1: Word;
  Ye, Mo, Da: Word;
begin
  Result := 0;
  { Counters }
  Result := Result xor GetHighPrecisionCounter;
  Result := Result xor (Int64(GetTick) shl 32);

  { System Time }
  DecodeTime(Time, H, Mi, S, S1);
  Result := Result xor Int64(H) xor (Int64(Mi) shl 8) xor (Int64(S1) shl 16) xor (Int64(S) shl 24);
  { System Date }
  DecodeDate(Date, Ye, Mo, Da);
  Result := Result xor (Int64(Ye) shl 32) xor (Int64(Mo) shl 48) xor (Int64(Da) shl 56);
end;

{$IFNDEF DOT_NET}

function HashBuffer(const Buffer: PByte; const Len: Integer): LongWord;
var
  I: Integer;
  P: PByte;
begin
  Result := 0;
  P := Buffer;
  for I := 1 to Len do
  begin
    Result := Result xor (LongWord(P^) shl ((I mod 7) * 4));
    Inc(P);
  end;
end;

function StrHashB(const S: RawByteString): LongWord;
var
  L: Integer;
begin
  Result := 0;
  L := Length(S);
  if L <= 0 then
    exit;
  Result := HashBuffer(@S[1], Length(S));
end;
{$ENDIF}
{$IFDEF MSWIN}

function GetCPUFrequency: Int64;
var
  F: Int64;
begin
  F := 0;
  if not QueryPerformanceFrequency(F) then
    F := 0;
  Result := F;
end;
{$ENDIF}
{$IFDEF MSWIN}
{$IFNDEF DOT_NET}

function StrLenA(const A: PAnsiChar): Integer;
var
  L: Integer;
begin
  if not Assigned(A) then
  begin
    Result := 0;
    exit;
  end;
  L := 0;
  while A[L] <> #0 do
    Inc(L);
  Result := L;
end;

function StrPasB(const A: PAnsiChar): RawByteString;
var
  I, L: Integer;
begin
  L := StrLenA(A);
  SetLength(Result, L);
  if L = 0 then
    exit;
  I := 0;
  while I < L do
  begin
    Result[I + 1] := A[I];
    Inc(I);
  end;
end;

function GetOSUserName: RawByteString;
var
  L: LongWord;
  B: array [0 .. 258] of Byte;
begin
  L := 256;
  FillChar(B[0], Sizeof(B), 0);
  if GetUserNameA(@B, L) then
    Result := StrPasB(@B)
  else
    Result := '';
end;

function GetOSComputerName: RawByteString;
var
  L: LongWord;
  B: array [0 .. 258] of Byte;
begin
  L := 256;
  FillChar(B[0], Sizeof(B), 0);
  if GetComputerNameA(@B, L) then
    Result := StrPasB(@B)
  else
    Result := '';
end;
{$ENDIF}
{$ENDIF}
{$IFDEF UNIX}

function GetOSUserName: RawByteString;
var
  T: RawByteString;
begin
  T := GetEnvironmentVariable('USER');
  if T = '' then
    T := GetEnvironmentVariable('USERNAME');
  Result := T;
end;

function GetOSComputerName: RawByteString;
begin
  Result := GetEnvironmentVariable('HOSTNAME');
end;
{$ENDIF}
{$IFDEF MSWIN}

function WinRandomState: Int64;
var
  F: LongWord;
  H: THandle;
  T1, T2, T3, T4: TFileTime;
  A, B: LongWord;
  S: Int64;
begin
  S := 0;
  { Thread times }
  F := GetCurrentThreadID;
  S := S xor F;
  H := GetCurrentThread;
  S := S xor H;
  GetThreadTimes(H, T1, T2, T3, T4);
  A := T1.dwLowDateTime xor T2.dwLowDateTime xor T3.dwLowDateTime xor T4.dwLowDateTime;
  B := T1.dwHighDateTime xor T2.dwHighDateTime xor T3.dwHighDateTime xor T4.dwHighDateTime;
  S := S xor A;
  S := S xor (Int64(B) shl 32);
  { Process times }
  F := GetCurrentProcessId;
  S := S xor F;
  H := GetCurrentProcess;
  S := S xor H;
  GetProcessTimes(H, T1, T2, T3, T4);
  A := T1.dwLowDateTime xor T2.dwLowDateTime xor T3.dwLowDateTime xor T4.dwLowDateTime;
  B := T1.dwHighDateTime xor T2.dwHighDateTime xor T3.dwHighDateTime xor T4.dwHighDateTime;
  S := S xor A;
  S := S xor (Int64(B) shl 32);
  { System times }
{$IFDEF DELPHI2010_UP}
  GetSystemTimes(T1, T2, T3);
  A := T1.dwLowDateTime xor T2.dwLowDateTime xor T3.dwLowDateTime;
  B := T1.dwHighDateTime xor T2.dwHighDateTime xor T3.dwHighDateTime;
  S := S xor A;
  S := S xor (Int64(B) shl 32);
{$ENDIF}
  Result := S;
end;
{$ENDIF}

{ }
{ RandomSeed }
{ The random seed is generated from a startup seed, a fixed seed, a }
{ variable seed and an entropy seed. }
{ The startup seed is initialised on module initialisation. }
{ The fixed seed is randomised on the first call to RandomSeed. }
{ The variable seed is randomised on every call to RandomSeed. }
{ }
var
  EntropySeed: Int64 = 0;
  StartupSeed: Int64 = 0;
  FixedSeedInit: Boolean = False;
  FixedSeed: Int64 = 0;
  VariableSeed: Int64 = 0;

function SeedMix1(const A, B: LongWord): Int64;
begin
  Result := Int64(lcRandom3(A)) or (Int64(lcRandom4(B)) shl 32);
end;

function SeedMix2(const A, B: LongWord): Int64;
begin

  Result := Int64(lcRandom1(A)) or (Int64(lcRandom2(B)) shl 32);
end;

function SeedMix3(const A, B: LongWord): Int64;
begin
  Result := Int64(lcRandom2(A)) or (Int64(lcRandom5(B)) shl 32);
end;

function SeedMix4(const A, B: LongWord): Int64;
begin
  Result := Int64(lcRandom4(A)) or (Int64(lcRandom2(B)) shl 32);
end;

function SeedMix5(const A, B: LongWord): Int64;
begin
  Result := Int64(lcRandom5(A)) or (Int64(lcRandom1(B)) shl 32);
end;

function SeedMix1_64(const S: Int64): Int64;
begin
  Result := SeedMix1(LongWord(S), LongWord(S shr 32));
end;

function SeedMix2_64(const S: Int64): Int64;
begin
  Result := SeedMix2(LongWord(S), LongWord(S shr 32));
end;

function SeedMix3_64(const S: Int64): Int64;
begin
  Result := SeedMix3(LongWord(S), LongWord(S shr 32));
end;

function SeedMix4_64(const S: Int64): Int64;
begin
  Result := SeedMix4(LongWord(S), LongWord(S shr 32));
end;

function SeedMix5_64(const S: Int64): Int64;
begin
  Result := SeedMix5(LongWord(S), LongWord(S shr 32));
end;

procedure AddEntropy(const Value: Int64);
var
  S: Int64;
begin
  S := EntropySeed xor Value;
  S := SeedMix1_64(S);
  EntropySeed := S;
end;

// The StartupSeed is initialised on module initialisation
procedure InitStartupSeed;
var
  S: Int64;
begin
  { Initialise startup seed }
  S := RandomState;

  S := SeedMix2_64(S);

  StartupSeed := S;

  { Initialise entropy seed }
  AddEntropy(RandomState);
end;

// The FixedSeed is initialised on the first call to RandomSeed
procedure InitFixedSeed;
var
  S: Int64;
{$IFNDEF ManagedCode}
  Q: Pointer;
{$ENDIF}
{$IFDEF UNIX}
  T: RawByteString;
{$ENDIF}
begin
  { Startup Seed }
  S := StartupSeed;
  { System State }
  S := S xor RandomState;
{$IFDEF MSWIN}
  S := S xor WinRandomState;
{$ENDIF}
  { Pointer Values }
{$IFNDEF ManagedCode}
  Q := @FixedSeed; // Global variable
  S := Int64(S + NativeUInt(Q));
  Q := @S; // Local variable
  S := Int64(S + NativeUInt(Q));
  GetMem(Q, 17); // Heap memory
  S := Int64(S + NativeUInt(Q));
  FreeMem(Q);
{$ENDIF}
{$IFDEF MSWIN}
  { CPU Frequency }
  S := S xor GetCPUFrequency;
{$IFNDEF ManagedCode}
  { OS User Name }
  S := Int64(S + StrHashB(GetOSUserName));
  { OS Computer Name }
  S := Int64(S + StrHashB(GetOSComputerName));
{$ENDIF}
{$ENDIF}
{$IFDEF UNIX}
  { OS User Name }
  S := Int64(S + StrHashB(GetOSUserName));
  { OS Computer Name }
  S := Int64(S + StrHashB(GetOSComputerName));
  { PPID }
  S := Int64(S + StrHashB(GetEnvironmentVariable('PPID')));
{$ENDIF}
  { System Timing }
  S := Int64(S + RandomState);
  Sleep(0);
  S := Int64(S + RandomState);
  Sleep(1);
  S := Int64(S + RandomState);
{$IFDEF MSWIN}
  S := Int64(S + WinRandomState);
{$ENDIF}
  Sleep(0);
  S := Int64(S + RandomState);
  { Mix bits }
  S := SeedMix3_64(S);
  { Save fixed seed }
  FixedSeed := S;
  FixedSeedInit := True;
end;

function RandomSeed32: LongWord;
var
  S: Int64;
begin
  { Fixed Seed }
  if not FixedSeedInit then
    InitFixedSeed;
  S := FixedSeed;
  { Entropy Seed }
  S := Int64(S + EntropySeed);
  { Variable Seed }
  S := Int64(S + VariableSeed);
  { System State }
  S := Int64(S + RandomState);
{$IFDEF MSWIN}
  S := Int64(S + WinRandomState);
{$ENDIF}
  { Mix bits }
  S := SeedMix5_64(S);
  { Update variable seed }
  VariableSeed := VariableSeed xor S;
  VariableSeed := SeedMix4_64(VariableSeed);
  { Mix/Reduce seed into result }
  Result := LongWord(S) xor LongWord(S shr 32);
end;

procedure RandomSeedFinalise;
begin
  EntropySeed := 0;
  StartupSeed := 0;
  FixedSeed := 0;
  VariableSeed := 0;
end;

{ }
{ Mother-of-All pseudo random number generator }
{ This is a multiply-with-carry or recursion-with-carry generator. }
{ It has a cycle length of 3E+47. }
{ It was invented by George Marsaglia. }
{ }
var
  moaSeeded: Boolean = False;
  moaX: array [0 .. 3] of LongWord;
  moaC: LongWord;

procedure moaInitSeed(const Seed: LongWord);
var
  I: Integer;
  S: LongWord;
begin
  S := Seed;
  for I := 0 to 3 do
  begin
    S := lcRandom1(S);
    moaX[I] := S;
  end;
  moaC := lcRandom1(S);
  moaSeeded := True;
end;

function moaRandom32: LongWord;
var
  S: Int64;
  Xn: LongWord;
begin
  if not moaSeeded then
    moaInitSeed(RandomSeed32);
  S := 2111111111 * Int64(moaX[0]) + 1492 * Int64(moaX[1]) + 1776 * Int64(moaX[2]) + 5115 * Int64(moaX[3]) + Int64(moaC);
  moaC := LongWord(S shr 32);
  Xn := LongWord(S);
  moaX[0] := moaX[1];
  moaX[1] := moaX[2];
  moaX[2] := moaX[3];
  moaX[3] := Xn;
  Result := Xn;
end;

function moaRandomFloat: Extended;
begin
  Result := moaRandom32 / High(LongWord);
end;

procedure moaFinalise;
begin
  if moaSeeded then
  begin
    moaX[0] := 0;
    moaX[1] := 0;
    moaX[2] := 0;
    moaX[3] := 0;
    moaC := 0;
  end;
end;

{ }
{ Multiply-With-Carry pseudo random number generator mentioned by George }
{ Marsaglia in his paper on the Mother-of-All generator: }
{ " Here is an interesting simple MWC generator with period > 2^92, for }
{ 32-bit arithmetic: }
{ x[n]=1111111464*(x[n-1]+x[n-2]) + carry mod 2^32. }
{ Suppose you have functions, say top() and bot(), that give the top and }
{ bottom halves of a 64-bit result.  Then, with initial 32-bit x, y and }
{ carry c,  simple statements such as }
{ y=bot(1111111464*(x+y)+c) }
{ x=y }
{ c=top(y) }
{ will, repeated, give over 2^92 random 32-bit y's. " }
{ }
var
  mwcSeeded: Boolean = False;
  mwcX: LongWord;
  mwcY: LongWord;
  mwcC: LongWord;

procedure mwcInitSeed(const Seed: LongWord);
begin
  mwcX := lcRandom2(Seed);
  mwcY := lcRandom2(mwcX);
  mwcC := lcRandom2(mwcY);
  mwcSeeded := True;
end;

function mwcRandom32: LongWord;
var
  S, T: UInt64;
begin
  if not mwcSeeded then
    mwcInitSeed(RandomSeed32);
  S := 1111111464;
{$IFOPT Q+}{$DEFINE QOn}{$Q-}{$ELSE}{$UNDEF QOn}{$ENDIF}
  T := mwcX;
  T := T + mwcY;
  S := S * T;
  S := S + mwcC;
{$IFDEF QOn}{$Q+}{$ENDIF}
  Result := LongWord(S);
  mwcX := mwcY;
  mwcY := Result;
  mwcC := LongWord(S shr 32);
end;

function mwcRandomFloat: Extended;
begin
  Result := mwcRandom32 / High(LongWord);
end;

procedure mwcFinalise;
begin
  if mwcSeeded then
  begin
    mwcX := 0;
    mwcY := 0;
    mwcC := 0;
  end;
end;

{ }
{ Universal random number generator proposed by Marsaglia, Zaman, and Tsang. }
{ FSU-SCRI-87-50 }
{ It has a period of 2^144 = 2E+43. }
{ Only 24 bits are guarantueed to be completely random. }
{ This generator passes all known statistical tests on randomness. }
{ The algorithm is a combination of a Fibonacci sequence and an arithmetic }
{ sequence. }
{ }
var
  urnSeeded: Boolean = False;
  urnU: array [1 .. 97] of Double;
  urnC: Double;
  urnCD: Double;
  urnCM: Double;
  urnI: Integer;
  urnJ: Integer;

procedure urnInit(const IJ, KL: Integer);
var
  I, J, K, L: Integer;
  F, G, M: Integer;
  S, T: Double;
begin
  Assert((IJ >= 0) and (IJ <= 31328) and (KL >= 0) and (KL <= 30081));
  I := (IJ div 177) mod 177 + 2;
  J := IJ mod 177 + 2;
  K := (KL div 169) mod 178 + 1;
  L := KL mod 169;
  for F := 1 to 97 do
  begin
    S := 0.0;
    T := 0.5;
    for G := 1 to 24 do
    begin
      M := (((I * J) mod 179) * K) mod 179;
      I := J;
      J := K;
      K := M;
      L := (53 * L + 1) mod 169;
      if ((L * M) mod 64 >= 32) then
        S := S + T;
      T := T * 0.5;
    end;
    urnU[F] := S;
  end;
  urnC := 362436.0 / 16777216.0;
  urnCD := 7654321.0 / 16777216.0;
  urnCM := 16777213.0 / 16777216.0;
  urnI := 97;
  urnJ := 33;
  urnSeeded := True;
end;

procedure urnInitSeed(const Seed: LongWord);
begin
  urnInit((Seed and $FFFF) mod 30000, (Seed shr 16) mod 30000);
end;

function urnRandomFloat: Double;
var
  R: Double;
begin
  if not urnSeeded then
    urnInitSeed(RandomSeed32);
  R := urnU[urnI] - urnU[urnJ];
  if R < 0.0 then
    R := R + 1.0;
  urnU[urnI] := R;
  Dec(urnI);
  if urnI = 0 then
    urnI := 97;
  Dec(urnJ);
  if urnJ = 0 then
    urnJ := 97;
  urnC := urnC - urnCD;
  if urnC < 0.0 then
    urnC := urnC + urnCM;
  R := R - urnC;
  if R < 0.0 then
    R := R + 1.0;
  Result := R;
end;

function urnRandom32: LongWord;
begin
  Result := LongWord(Trunc(urnRandomFloat * 4294967295.0));
end;

procedure urnFinalise;
var
  I: Integer;
begin
  if urnSeeded then
  begin
    for I := 1 to 97 do
      urnU[I] := 0.0;
    urnC := 0.0;
    urnCD := 0.0;
    urnCM := 0.0;
    urnI := 0;
    urnJ := 0;
  end;
end;

{ }
{ Uniform Random }
{ }
procedure SetRandomSeed(const Seed: LongWord);
begin
  moaInitSeed(Seed);
end;

function RandomUniform32: LongWord;
begin
  Result := moaRandom32;
end;

function RandomUniform(const N: Integer): Integer;
begin
  if N <= 1 then
    Result := 0
  else
    Result := Integer(RandomUniform32 mod LongWord(N));
end;

function RandomUniform16: Word;
var
  I: LongWord;
begin
  I := RandomUniform32;
  I := I xor (I shr 16);
  Result := Word(I and $FFFF);
end;

function RandomByte: Byte;
var
  I: LongWord;
begin
  I := RandomUniform32;
  I := I xor (I shr 8) xor (I shr 16) xor (I shr 24);
  Result := Byte(I and $FF);
end;

function RandomByteNonZero: Byte;
begin
  repeat
    Result := RandomByte;
  until Result <> 0;
end;

function RandomBoolean: Boolean;
begin
  Result := RandomUniform32 and 1 = 1;
end;

function RandomFloat: Extended;
begin
  Result := urnRandomFloat;
end;

function RandomInt64: Int64;
begin
  Result := Int64(RandomUniform32) or (Int64(RandomUniform32) shl 32);
end;

function RandomInt64(const N: Int64): Int64;
begin
  if N <= 0 then
    Result := 0
  else
  begin
    Result := RandomInt64;
    if Result < 0 then
      Result := -Result;
    Result := Result mod N;
  end;
end;

const
  HexDigitsHi: String = '0123456789ABCDEF';
  // HexDigitsHiA : RawByteString = '0123456789ABCDEF';
  HexDigitsHiU: UnicodeString = '0123456789ABCDEF';
  HexDigitsLo: String = '0123456789abcdef';
  // HexDigitsLoA : RawByteString = '0123456789abcdef';
  HexDigitsLoU: UnicodeString = '0123456789abcdef';

function RandomHex(const Digits: Integer; const UpperCase: Boolean): String;
var
  I: Integer;
  D: Integer;
  C: Char;
begin
  if Digits <= 0 then
  begin
    Result := '';
    exit;
  end;
  SetLength(Result, Digits);
  for I := 1 to Digits do
  begin
    D := 1 + RandomUniform(16);
    if UpperCase then
      C := HexDigitsHi[D]
    else
      C := HexDigitsLo[D];
    Result[I] := C;
  end;
end;

{
  function RandomHexA(const Digits: Integer; const UpperCase: Boolean): RawByteString;
  var
  I : Integer;
  D : Integer;
  C : AnsiChar;
  begin
  if Digits <= 0 then
  begin
  Result := '';
  exit;
  end;
  SetLength(Result, Digits);
  for I := 1 to Digits do
  begin
  D := 1 + RandomUniform(16);
  if UpperCase then
  C := HexDigitsHiA[D]
  else
  C := HexDigitsLoA[D];
  Result[I] := C;
  end;
  end;

  function RandomHexW(const Digits: Integer; const UpperCase: Boolean): WideString;
  var
  I : Integer;
  D : Integer;
  C : WideChar;
  begin
  if Digits <= 0 then
  begin
  Result := '';
  exit;
  end;
  SetLength(Result, Digits);
  for I := 1 to Digits do
  begin
  D := 1 + RandomUniform(16);
  if UpperCase then
  C := HexDigitsHiU[D]
  else
  C := HexDigitsLoU[D];
  Result[I] := C;
  end;
  end;
}

function RandomHexU(const Digits: Integer; const UpperCase: Boolean): UnicodeString;
var
  I: Integer;
  D: Integer;
  C: WideChar;
begin
  if Digits <= 0 then
  begin
    Result := '';
    exit;
  end;
  SetLength(Result, Digits);
  for I := 1 to Digits do
  begin
    D := 1 + RandomUniform(16);
    if UpperCase then
      C := HexDigitsHiU[D]
    else
      C := HexDigitsLoU[D];
    Result[I] := C;
  end;
end;

{
  function RandomUpperAlphaStrA(const Length: Integer): RawByteString;
  var
  I : Integer;
  begin
  if Length <= 0 then
  begin
  Result := '';
  exit;
  end;
  SetLength(Result, Length);
  for I := 1 to Length do
  Result[I] := AnsiChar(Ord('A') + RandomUniform(26));
  end;

  const
  Vowels         = 'AEIOUY';
  VowelCount     = Length(Vowels);
  Consonants     = 'BCDFGHJKLMNPQRSTVWXZ';
  ConsonantCount = Length(Consonants);

  function RandomPseudoWordA(const Length: Integer): RawByteString;
  var
  I, A, P, T : Integer;
  begin
  if Length <= 0 then
  begin
  Result := '';
  exit;
  end;
  SetLength(Result, Length);
  P := -1;
  A := RandomUniform(2);
  for I := 1 to Length do
  begin
  case A of
  0 : Result[I] := AnsiChar(Vowels[RandomUniform(VowelCount) + 1]);
  1 : Result[I] := AnsiChar(Consonants[RandomUniform(ConsonantCount) + 1]);
  end;
  T := A;
  if A = P then
  A := A xor 1
  else
  A := RandomUniform(2);
  P := T;
  end;
  end;

  const
  PasswordSymbolChars = '!?@%$&-*#';
  PasswordSymbolCharCount = Length(PasswordSymbolChars);
  PasswordNumberChars = '0123456789';
  PasswordNumberCharCount = Length(PasswordNumberChars);

  function RandomPasswordA(const MinLength, MaxLength: Integer;
  const CaseSensitive, UseSymbols, UseNumbers: Boolean): RawByteString;
  var
  I, J, K, N, Length : Integer;
  C : AnsiChar;
  begin
  if (MaxLength <= 0) or (MaxLength < MinLength) then
  begin
  Result := '';
  exit;
  end;
  if MinLength = MaxLength then
  Length := MinLength
  else
  Length := MinLength + RandomUniform(MaxLength - MinLength + 1);
  Result := RandomPseudoWordA(Length);
  if CaseSensitive then
  begin
  N := RandomUniform(1 + Length div 2);
  for I := 0 to N - 1 do
  begin
  J := RandomUniform(Length);
  C := Result[J + 1];
  if C in ['A'..'Z'] then
  Result[J + 1] := AnsiChar(Ord(C) + 32);
  end;
  end;
  if UseSymbols then
  begin
  N := RandomUniform(1 + Length div 4);
  for I := 0 to N - 1 do
  begin
  J := RandomUniform(Length);
  K := RandomUniform(PasswordSymbolCharCount);
  Result[J + 1] := AnsiChar(PasswordSymbolChars[K + 1]);
  end;
  end;
  if UseNumbers then
  begin
  N := RandomUniform(1 + Length div 4);
  for I := 0 to N - 1 do
  begin
  J := RandomUniform(Length);
  K := RandomUniform(PasswordNumberCharCount);
  Result[J + 1] := AnsiChar(PasswordNumberChars[K + 1]);
  end;
  end;
  end;
}

const
  Vowels = 'AEIOUY';
  VowelCount = Length(Vowels);
  Consonants = 'BCDFGHJKLMNPQRSTVWXZ';
  ConsonantCount = Length(Consonants);

function RandomPseudoWord(const Length: Integer): String;
var
  I, A, P, T: Integer;
begin
  if Length <= 0 then
  begin
    Result := '';
    exit;
  end;
  SetLength(Result, Length);
  P := -1;
  A := RandomUniform(2);
  for I := 1 to Length do
  begin
    case A of
      0:
        Result[I] := Char(Vowels[RandomUniform(VowelCount) + 1]);
      1:
        Result[I] := Char(Consonants[RandomUniform(ConsonantCount) + 1]);
    end;
    T := A;
    if A = P then
      A := A xor 1
    else
      A := RandomUniform(2);
    P := T;
  end;
end;

const
  PasswordSymbolChars = '!?@%$&-*#';
  PasswordSymbolCharCount = Length(PasswordSymbolChars);
  PasswordNumberChars = '0123456789';
  PasswordNumberCharCount = Length(PasswordNumberChars);

function RandomPassword(const MinLength, MaxLength: Integer; const CaseSensitive, UseSymbols, UseNumbers: Boolean): String;
var
  I, J, K, N, Length: Integer;
  C: Char;
begin
  if (MaxLength <= 0) or (MaxLength < MinLength) then
  begin
    Result := '';
    exit;
  end;
  if MinLength = MaxLength then
    Length := MinLength
  else
    Length := MinLength + RandomUniform(MaxLength - MinLength + 1);
  // Result := RandomPseudoWordA(Length);
  Result := RandomPseudoWord(Length);
  if CaseSensitive then
  begin
    N := RandomUniform(1 + Length div 2);
    for I := 0 to N - 1 do
    begin
      J := RandomUniform(Length);
      C := Result[J + 1];
      if C in ['A' .. 'Z'] then
        Result[J + 1] := Char(Ord(C) + 32);
    end;
  end;
  if UseSymbols then
  begin
    N := RandomUniform(1 + Length div 4);
    for I := 0 to N - 1 do
    begin
      J := RandomUniform(Length);
      K := RandomUniform(PasswordSymbolCharCount);
      Result[J + 1] := Char(PasswordSymbolChars[K + 1]);
    end;
  end;
  if UseNumbers then
  begin
    N := RandomUniform(1 + Length div 4);
    for I := 0 to N - 1 do
    begin
      J := RandomUniform(Length);
      K := RandomUniform(PasswordNumberCharCount);
      Result[J + 1] := Char(PasswordNumberChars[K + 1]);
    end;
  end;
end;

{ }
{ Normal Random }
{ }
var
  HasRandomNormal: Boolean = False;
  ARandomNormal: Extended;

function RandomNormalF: Extended;
var
  fac, R, v1, v2: Extended;
begin
  if not HasRandomNormal then
  begin
    Repeat
      v1 := 2.0 * RandomFloat - 1.0;
      v2 := 2.0 * RandomFloat - 1.0;
      R := Sqr(v1) + Sqr(v2);
    Until R < 1.0;
    fac := Sqrt(-2.0 * ln(R) / R);
    ARandomNormal := v1 * fac;
    Result := v2 * fac;
    HasRandomNormal := True;
  end
  else
  begin
    Result := ARandomNormal;
    HasRandomNormal := False;
  end;
end;

procedure RandomNormalFinalise;
begin
  if HasRandomNormal then
    ARandomNormal := 0.0;
end;

{ }
{ Test cases }
{ }
{$IFDEF DEBUG}
{$ASSERTIONS ON}

procedure SelfTest;
var
  I, L: Integer;
  A, B, C: LongWord;
  V, W: Int64;
  T1, T2: Int64;
begin
  // Assert(Length(RandomPasswordA(0, 0, True, True, True)) = 0);
  Assert(Length(RandomPassword(1, 1, True, True, True)) = 1);
  for I := 1 to 100 do
  begin
    // L := Length(RandomPasswordA(5, 16, True, True, True));
    L := Length(RandomPassword(5, 16, True, True, True));
    Assert((L >= 5) and (L <= 16));
  end;
  // Assert(Length(RandomHexA(32)) = 32);
  Assert(Length(RandomHex(32)) = 32);
  // Note: These are simple sanity tests that may fail occasionally
  // RandomSeed/RandomUniform
  // - Check for unique numbers
  // - Check average value of random numbers
  T1 := 0;
  T2 := 0;
  for I := 1 to 10000 do
  begin
    A := RandomSeed32;
    B := RandomSeed32;
    C := RandomSeed32;
    Assert(not((A = B) and (B = C)), 'RandomSeed');
    T1 := T1 + A + B + C;
    A := RandomUniform32;
    B := RandomUniform32;
    C := RandomUniform32;
    Assert(not((A = B) and (B = C)), 'RandomUniform');
    T2 := T2 + A + B + C;
  end;
  T1 := T1 div 30000;
  Assert((T1 > 1600000000) and (T1 < 2800000000), 'RandomSeed');
  T2 := T2 div 30000;
  Assert((T2 > 1600000000) and (T2 < 2800000000), 'RandomUniform');
  // RandomInt64
  // - Check sign
  I := 0;
  repeat
    Inc(I);
    V := RandomInt64;
    W := RandomInt64;
  until ((V < 0) and (W > 0)) or (I = 32);
  Assert((V < 0) and (W > 0), 'RandomInt64');
end;
{$ENDIF}

initialization

InitStartupSeed;

finalization

RandomSeedFinalise;
moaFinalise;

end.
