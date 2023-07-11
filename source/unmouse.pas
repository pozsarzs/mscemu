{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | unmouse.pas                                                              | }
{ | mouse handler unit                                                       | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

unit unmouse;
interface
uses
  dos;
var
  r: registers;

procedure initmouse;
procedure mousecursor(show: boolean);
function mouseposx: integer;
function mouseposy: integer;
function mousestatus: integer;

implementation

procedure initmouse;
begin
  r.ax := 0;
  intr($33,r);
end;

procedure mousecursor(show: boolean);
begin
  if show then r.ax := 1 else r.ax := 2;
  intr($33,r);
end;

function mouseposx: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mouseposx := r.cx;
end;

function mouseposy: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mouseposy := r.dx;
end;

function mousestatus: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mousestatus := r.ax;
end;
end.
