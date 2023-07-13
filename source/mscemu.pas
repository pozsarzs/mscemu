{ +--------------------------------------------------------------------------+ }
{ | MSCEmu v0.1 * Mini serial console emulator for MM8D                      | }
{ | Copyright (C) 2023 Pozsar Zsolt <pozsarzs@gmail.com>                     | }
{ | mscemu.pas                                                               | }
{ | main program                                                             | }
{ +--------------------------------------------------------------------------+ }

{
  This program is Public Domain, you can redistribute it and/or modify
  it under the terms of the Creative Common Zero Universal version 1.0.
}

program mscemu;
uses
  crt,
  unmouse,
  unserial,
  unscreen;
var
  { general variables }
  b:  byte;
  c:  char;
  s:  string;
  p:  byte;
  w:  word;
const
  { signs of the values }
  CH0: array[0..7] of string  = ('T','','BE','LP','HP','T1','T2','T3');
  CH1: array[0..7] of string  = ('T','RH','OM','CM','BE','LA','VE','HE');
  SP:  array[0..6] of string  = ('Urms','Irms','cosFi','P','Q','S','qv');
  { description of the signs }
  DCH0: array[0..7] of string = ('external temperature in øC',
                                 '',
                                 'overcurrent breaker error',
                                 'low water pressure error',
                                 'high water pressure error',
                                 'status of the 1st water tube',
                                 'status of the 2nd water tube',
                                 'status of the 3rd water tube');
  DCH1: array[0..7] of string = ('internal temperature in øC',
                                 'internal relative humidity in %',
                                 'operation mode (hyphae/mushroom)',
                                 'control mode (auto/manual)',
                                 'overcurrent breaker error',
                                 'status of the lamp output',
                                 'status of the ventilator output',
                                 'status of the heater output');
  DSP:  array[0..6] of string = ('effective voltage in V',
                                 'effective current in A',
                                 'power factor',
                                 'active power in W',
                                 'reactive power in VAr',
                                 'apparent power in VA',
                                 'water flow rate in l/min');

{ write footer to screen }
procedure footer(page: byte);
var
  b: byte;
const
  FTR: array[0..1] of string=(' &ESC Exit',
                              ' &F1 Help  &ESC Exit');
begin
  textcolor(black);
  textbackground(lightgray);
  window(1,1,80,25);
  gotoxy(1,25); clreol;
  for b := 1 to length(FTR[page]) do
  begin
   if FTR[page][b] = '&' then textcolor(red) else write(FTR[page][b]);
   if FTR[page][b] = ' ' then textcolor(black);
  end;
end;

{ write frame to screen }
procedure frame(page: byte);
var
  b: byte;
begin
  textcolor(white);
  case page of
    0: begin
         { lines }
         textbackground(black);
         window(5,4,79,22);
         clrscr;
         textbackground(cyan);
         window(4,3,77,21);
         clrscr;
         window(1,1,80,25);
         gotoxy(4,3); write('Ú');
         gotoxy(77,3); write('¿');
         for b := 5 to 76 do
         begin
           gotoxy(b,3); write('Ä');
           gotoxy(b,21); write('Ä');
         end;
         for b := 4 to 20 do
         begin
           gotoxy(4,b); write('³');
           gotoxy(77,b); write('³');
         end;
         gotoxy(4,21); write('À');
         gotoxy(77,21); write('Ù');
         { titles }
         gotoxy(6,3); write(' Help ');
       end;
    1: begin
         { lines }
         textbackground(blue);
         window(1,1,80,25);
         clrscr;
         gotoxy(1,1); write('Ú');
         gotoxy(80,1); write('¿');
         for b := 2 to 79 do
         begin
           gotoxy(b,1); write('Ä');
           gotoxy(b,11); write('Ä');
           gotoxy(b,16); write('Ä');
           gotoxy(b,19); write('Ä');
           gotoxy(b,24); write('Ä');
         end;
         for b := 2 to 24 do
         begin
           gotoxy(1,b); write('³');
           if ((b > 1) and (b < 11)) or ((b > 11) and (b < 16)) then
           begin
             gotoxy(17,b); write('³');
           end;
           gotoxy(80,b); write('³');
         end;
         gotoxy(1,24); write('À');
         gotoxy(80,24); write('Ù');
         { titles }
         gotoxy(3,1); write(' Status and values ');
         gotoxy(70,1); write(' HH:MM:SS ');
         gotoxy(3,11); write(' Override ');
         gotoxy(3,16); write(' Consumption ');
         gotoxy(3,19); write(' Log ');
         for b := 0 to 7 do
         begin
           gotoxy(3,b + 3);
           if length(ch0[b]) > 0 then write(CH0[b] + ':');
           gotoxy(19,b + 3); write(CH1[b] + ':');
           if b > 4 then
           begin
             gotoxy(3,b + 8);
             if length(ch0[b]) > 0 then write(CH0[b] + ':');
             gotoxy(19,b + 8); write(CH1[b] + ':');
           end;
         end;
         for b := 0 to 1 do
         begin
           gotoxy(3,b + 17); write(SP[b] + ':');
           gotoxy(23,b + 17); write(SP[b+2] + ':');
           gotoxy(43,b + 17); write(SP[b+4] + ':');
           gotoxy(63,b + 17); if b + 6 < 7 then write(SP[b+6] + ':');
         end;
         textcolor(yellow);
         gotoxy(3,2); write('CH:');
         gotoxy(19,2); write('CH:');
         gotoxy(3,12); write('CH:');
         gotoxy(19,12); write('CH:');
         for b := 0 to 8 do
         begin
           if b = 0 then gotoxy(8,2) else gotoxy(17 + b * 7,2); write('#',b);
           if b = 0 then gotoxy(8,12) else gotoxy(17 + b * 7,12); write('#',b);
         end;
         { log box }
         textcolor(lightgray);
         textbackground(black);
         window(3,20,78,23);
         clrscr;
         window(1,1,80,25);
         textcolor(white);
         textbackground(blue);
       end;
  end;
  { footer }
  footer(page);
end;

{ write log to screen }
procedure writelog(s: string);
begin
  if length(s) > 0 then
  begin
    textcolor(lightgray);
    textbackground(black);
    window(3,20,78,23);
    if p = 5 then
    begin
      gotoxy(1,p - 1);
      writeln;
    end;
    if p = 5 then gotoxy(2,p - 1) else gotoxy(2,p);
    write(s);
    if p < 5 then inc(p);
  end;
end;

{ write CH data to screen }
procedure writechdata(s: string);
var
  c: char;

  procedure write01(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #0: write('0');
      #1: write('1');
      #2: write('0');
      #3: write('1');
    end;
  end;

  procedure writeovr(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #2: write('off');
      #3: write('on');
    else
      write('neut.');
    end;
  end;

  procedure writeam(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    if c = #0 then write('A') else write('M');
  end;

  procedure writehmd(c: char; x, y: byte);
  begin
    gotoxy(x,y);
    case c of
      #0: write('H');
      #1: write('M');
    else
      write('D');
    end;
  end;

begin
  if length(s) >= 10 then
  begin
    textcolor(white);
    textbackground(blue);
    window(1,1,80,25);
    if s[3] = #0 then
    begin
      { CH #0 }
      for b := 4 to 10 do
        if b = 7 then
        begin
          gotoxy(8,3); write(byte(s[7]),' øC ');
        end else
          if b < 7 then write01(s[b],8,b + 1) else write01(s[b],8,b);
      for b := 8 to 10 do
        writeovr(s[b],8,b + 5);
    end else
    begin
      { CH #1-8 }
      gotoxy(24 + (byte(s[3]) - 1) * 7,3); write(byte(s[4]),' øC');
      gotoxy(24 + (byte(s[3]) - 1) * 7,4); write(byte(s[5]),'%');
      writehmd(s[7],24 + (byte(s[3]) - 1) * 7,5);
      writeam(s[8],24 + (byte(s[3]) - 1) * 7,6);
      for b := 9 to 13 do
        if b <> 10 then
          if b = 9
          then
            write01(s[b],24 + (byte(s[3]) - 1) * 7,b - 2)
          else
            write01(s[b],24 + (byte(s[3]) - 1) * 7,b - 3);
      for b := 11 to 13 do
        writeovr(s[b],24 + (byte(s[3]) - 1) * 7,b + 2)
    end;
  end;
end;

{ write SP data to screen }
procedure writespdata(s: string);
begin
  if length(s) = 16 then
  begin
    textcolor(white);
    textbackground(blue);
    window(1,1,80,25);
  end;
end;

{ show hint on footer }
procedure hint(x, y: integer);
var
  cleaned: boolean;


procedure show(s: string);
begin
  textcolor(black);
  textbackground(lightgray);
  window(1,1,80,25);
  gotoxy(30,25); clreol;
  gotoxy(80 - length(s),25);
  write(s);
  cleaned := false;
end;

procedure hide;
begin
  textcolor(black);
  textbackground(lightgray);
  window(1,1,80,25);
  gotoxy(30,25); clreol;
  show('Hint: move mouse cursor over value');
  cleaned := true;
end;

begin
  cleaned := false;
  { status and values of the CH #0 }
  if (x >= 3) and (y >=3 ) and (x <= 5) and (y <= 10)
    then show(DCH0[y - 3])
    else
      { status and values of the CH #1-8 }
      if (x >= 19) and (y >=3) and (x <= 21) and (y <=10)
      then show(DCH1[y - 3])
      else
        { override of the CH #0 }
        if (x >= 3) and (y >= 13) and (x <= 5) and (y <= 15)
        then show(DCH0[y - 8])
        else
          { override of the CH #1-8 }
          if (x >= 19) and (y >= 13) and (x <= 21) and (y <= 15)
          then show(DCH1[y - 8])
          else
            { consumption }
            if (x >= 3) and (y >= 17) and (x <= 7) and (y <= 18)
            then show(DSP[y - 17])
            else
              if (x >= 23) and (y >= 17) and (x <= 28) and (y <= 18)
              then show(DSP[y - 15])
              else
                if (x >= 43) and (y >= 17) and (x <= 44) and (y <= 18)
                then show(DSP[y - 13])
                else
                  if (x >= 63) and (y >= 17) and (x <= 65) and (y <= 17)
                  then show(DSP[y - 11])
                  else
                    if cleaned = false then hide;
end;

{ show help box }
procedure help;
var
  b: byte;
  c: char;

  function addspace(l: byte; s: string): string;
  begin
    s := s + ': ';
    while length(s) < l + 2 do
      s := s + ' ';
    addspace := s;
  end;

begin
  mousecursor(false);
  savescreen;
  mousecursor(true);
  frame(0);
  textcolor(white);
  textbackground(cyan);
  window(1,1,80,25);
  { content }
  for b:= 0 to 7 do
  begin
    if length(CH0[b]) > 0 then
    begin
      if b < 2
        then gotoxy(7,5 + b)
        else gotoxy(7,5 + b - 1);
      write(addspace(2,CH0[b]) + DCH0[b]);
    end;
    if length(CH1[b]) > 0 then
    begin
      gotoxy(7,13 + b); write(addspace(2,CH1[b]) + DCH1[b]);
    end;
    if length(SP[b]) > 0 then
      if b < 7 then
      begin
        gotoxy(46,5 + b); write(addspace(5,SP[b]) + DSP[b]);
      end;
  end;
  repeat
    if keypressed then c := readkey;
    if mouseclick(1,2,25,9,25) then c := #27;
    showtime;
  until c = #27;
  frame(1);
  mousecursor(false);
  restorescreen;
  mousecursor(true);
end;

begin
  { check command line parameter}
  w := COM1;
  if paramcount > 0 then
  begin
    if paramstr(1) = '1' then w := COM1 else
      if paramstr(1) = '2' then w := COM2 else
        if paramstr(1) = '3' then w := COM3 else
          if paramstr(1) = '4' then w := COM4 else
            begin
              writeln('Usage: mscemu.exe [1..4]');
              writeln('  1..4: COM #1..#4 port');
              halt(1);
            end;
  end;
  { init serial port }
  initserialport(w,unserial.PNoneParity or unserial.s1StopBit or unserial.d8DataBit);
  setspeed(unserial.bps9600);
  cursor(false);
  { start page }
  frame(1);
  { read from serial port and write data to screen }
  mousecursor(true);
  b := 0;
  s := '';
  p := 1;
  repeat
    c := #128;
    if keypressed then
    begin
      c := readkey;
      if c = #0 then c := readkey;
    end;
    if mouseclick(1,2,25,8,25) then c := #59;
    if mouseclick(1,11,25,18,25) then c := #27;
    if c = #59 then help;
    if dataready then
    begin
      s := s + receivechar;
      b := 0;
    end else b := b + 1;
    delay(1);
    if b > 200 then
    begin
      if (s[1] + s[2] <> 'CH') and (s[1] + s[2] <> 'SP') then writelog(s);
      if s[1] + s[2] = 'CH' then writechdata(s);
      if s[1] + s[2] = 'SP' then writespdata(s);
      s := '';
      b := 0;
      showtime;
      hint(mouseposx,mouseposy);
    end;
  until c = #27;
  textcolor(lightgray);
  textbackground(black);
  window(1,1,80,25);
  clrscr;
  cursor(true);
  mousecursor(false);
end.