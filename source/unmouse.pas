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
function mouseclick(button,x1,y1,x2,y2: byte): boolean;

implementation

{ initialize mouse }
procedure initmouse;
begin
  r.ax := 0;
  intr($33,r);
end;

{ show/hide mouse cursor }
procedure mousecursor(show: boolean);
begin
  if show then r.ax := 1 else r.ax := 2;
  intr($33,r);
end;

{ get x position of the mouse cursor }
function mouseposx: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mouseposx := (r.cx div 8) + 1;
end;

{ get y position of the mouse cursor }
function mouseposy: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mouseposy := (r.dx div 8) + 1 ;
end;

{ get status of buttons }
function mousestatus: integer;
begin
  r.ax := 5;
  r.bx := 0;
  intr($33,r);
  mousestatus := r.ax;
end;

{ detect button click and release }
function mouseclick(button,x1,y1,x2,y2: byte): boolean;
begin
  if (mouseposx >= x1) and (mouseposx <= x2) and
     (mouseposy >= y1) and (mouseposy <= y2) and
     (mousestatus = button) then
  begin
    repeat until mousestatus = 0;
    mouseclick := true;
  end else mouseclick := false;
end;
end.
