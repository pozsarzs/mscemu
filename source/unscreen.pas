{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | unscreen.pas                                                             | }
{ | screen handler unit                                                      | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

unit unscreen;
interface
var
  buffer:    array[1..4000] of byte;
  vmemcolor: array[1..25,1..80,1..2] of byte absolute $b800:0;
  vmemmono:  array[1..25,1..80,1..2] of byte absolute $b000:0;

procedure savescreen;
procedure restorescreen;
procedure cursor(show: boolean);

implementation

{ save screen content to memory }
procedure savescreen;
begin
  if byte(ptr($40,$49)^)=7
    then move(vmemmono,buffer,4000)
    else move(vmemcolor,buffer,4000);
end;

{ restore screen content from memory }
procedure restorescreen;
begin
  if byte(ptr($40,$49)^)=7
    then move(buffer,vmemmono,4000)
    else move(buffer,vmemcolor,4000);
end;

{ on/off cursor }
procedure cursor(show: boolean);
begin
  if show then
    asm
      MOV AL, $00;
      MOV AH, $01;
      MOV CL, $07;
      MOV CH, $06;
      INT $10
  end else
    asm
      MOV AL, $00;
      MOV AH, $01;
      MOV CL, $00;
      MOV CH, $10;
      INT $10
    end;
end;
end.
