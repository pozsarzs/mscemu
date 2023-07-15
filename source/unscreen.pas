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
uses
  crt,
  dos;
var
  buffer:    array[1..4000] of byte;
  vmemcolor: array[1..25,1..80,1..2] of byte absolute $b800:0;
  vmemmono:  array[1..25,1..80,1..2] of byte absolute $b000:0;

procedure savescreen;
procedure restorescreen;
procedure cursor(show: boolean);
procedure showtime;

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

{ show system time on the right top corner of the screen }
procedure showtime;
var
  h1, m1, s1, ss1: word;
  h2, m2, s2, ss2: word;
  s:               string;

  function addzero(w: word): string;
  begin
    str(w:0,s);
    if length(s) = 1 then s := '0' + s;
    addzero := s;
  end;

begin
  window(1,1,80,25);
  textbackground(blue);
  textcolor(white);
  gettime(h1,m1,s1,ss1);
  if (h1 <> h2) or (m1 <> m2) or (s1 <> s2) then
  begin
    gotoxy(71,1); write(addzero(h1));
    gotoxy(74,1); write(addzero(m1));
    gotoxy(77,1); write(addzero(s1));
    h2 := h1;
    m2 := m1;
    s2 := s1;
  end;
end;
end.
