//♡2022 by Kisspeace. https://github.com/kisspeace
program NsfwXxxScraperTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Windows,
  NetHttp.Scraper.NsfwXxx,
  NsfwXxx.Types,
  Net.HttpClient,
  XSuperObject,
  NsfwXxx.HTMLParser;

procedure WritelnWA(AStr: string; AAttrs: word);
var
  h: cardinal;
begin
  h := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(h, AAttrs);
  Writeln(AStr);
  SetConsoleTextAttribute(h, 7);
end;


function NewScraper: TNsfwXxxScraper;
begin
  Result := TNsfwXxxScraper.Create;
  with Result.WebClient do begin
    Asynchronous := false;
    AutomaticDecompression := [THttpCompressionMethod.Any];
    AllowCookies := false;
    Useragent                        := 'Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0';
    Customheaders['Accept']          := 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8';
    CustomHeaders['Accept-Language'] := 'en-US,en;q=0.5';
    CustomHeaders['Accept-Encoding'] := 'gzip, deflate';
    CustomHeaders['DNT']             := '1';
    CustomHeaders['Connection']      := 'keep-alive';
    CustomHeaders['Upgrade-Insecure-Requests'] := '1';
    CustomHeaders['Sec-Fetch-Dest']  := 'document';
    CustomHeaders['Sec-Fetch-Mode']  := 'navigate';
    CustomHeaders['Sec-Fetch-Site']  := 'same-origin';
    CustomHeaders['Pragma']          := 'no-cache';
    CustomHeaders['Cache-Control']   := 'no-cache';
  end;
end;

procedure Print(AItems: TNsfwXxxItemList);
var
  I: integer;
  str: string;
begin
  for I := 0 to AItems.Count - 1 do begin
    str := TJson.Stringify<TNsfwXxxItem>(AItems[i], true);
    str := (I + 1).ToString + ') ' + Str;
    writeln(str);
  end;
end;


var
  Client: TNsfwXxxScraper;
  I: integer;
  Items: TNsfwXxxItemList;
  Page: TNsfwXxxPostPage;
  Request: string;
  str: string;
  Item: TNsfwXxxItem;

  PrintItems: boolean = false;
  AutoStart: boolean  = true;

  procedure Test(ARequest: string; AUrlType: TNsfwUrlType);
  var
    Prefix: string;
  begin
    Prefix := 'GetItems test ' + ord(AurlType).ToString + ': ';
    try
      Items.Clear;
      Client.GetItems(items, ARequest, AUrlType, 1, newest, [image, video, gallery]);
      if ( Items.Count > 0 ) then begin
        WritelnWA(Prefix + 'OK', 10);
        if ( not Items[0].ValidId ) then
          WritelnWA('  ' + Prefix + ' INVALID ID', 14);
        if PrintItems then print(Items);
      end else begin
        WritelnWA(Prefix + '( Items < 1 )', 14);
      end;
    except
      on E: Exception do begin
        WritelnWA(Prefix + E.ClassName + ' - ' + E.Message, 12);
      end;
    end;
  end;

  procedure StartTest(AHost: string);
  begin
    Client.Host := AHost;
    Writeln('Host: ' + AHost);

    if not AutoStart then begin
      Write('Request: ');
      ReadLn(Request);
    end else begin
      Request := 'ass';
    end;

    Test(Request, Default);
    Item := Items[0];
    Test(Item.PostUrl, Related);
    Test(Item.Username, user);
    Test('/r/pawg', Category);

    //GetPage test
    try
      Page := Client.GetPage(Item.PostUrl);
      if Length(Page.Items) > 0 then begin
        WritelnWA('GetPage: OK', 10);
        if ( not Page.Items[0].ValidId ) then
          WritelnWA('  GetPage: INVALID ID', 14);
        if PrintItems then begin
          str := TJson.Stringify<TNsfwXxxPostPage>(Page, true);
          writeln(Str);
        end;
      end else begin
        WritelnWA('GetPage: ( Page.Items < 1 )', 14);
      end;
    except
      on E: Exception do begin
        WritelnWA('GetPage: ' + E.ClassName + ' - ' + E.Message, 12);
      end;
    end;
  end;

begin
  try
    Items := TNsfwXxxItemList.Create;
    Client := NewScraper;

    StartTest('https://nsfw.xxx');
    StartTest('https://pornpic.xxx');
    StartTest('https://hdporn.pics');

    Writeln('fin.');
    Readln;

  except
    on E: Exception do begin
      Writeln(E.ClassName, ': ', E.Message);
      readln;
    end;
  end;
end.
