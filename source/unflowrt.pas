{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | unflowrt.pas                                                             | }
{ | Calculate flow rate from raw value                                       | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

unit unflowrt;
interface

function qv(l: longint): real;

implementation

{ qv: water flow rate }
function qv(l: longint): real;
begin
  { 32767 = 100 l/min }
  qv := (l * 100) / 32767;
end;
end.
