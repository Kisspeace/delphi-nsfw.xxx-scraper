{* ♡2022 by Kisspeace. https://github.com/kisspeace
  v1.0.0
    https://github.com/Kisspeace/delphi-nsfw.xxx-scraper/issues/1 (mindjek07)
    Scraper support: hdporn.pics, pornpic.xxx
*}
unit NetHttp.Scraper.NsfwXxx;

interface
uses
  classes, Sysutils, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent,
  system.Generics.Collections, System.NetEncoding,
  NsfwXxx.Types, NsfwXxx.HTMLParser;

const
  URL_NSFWXXX = 'https://nsfw.xxx';

type

  TNsfwXxxScraper = class(TObject)
   private
     function Get(AUrl: string; AOut: TNsfwXXXItemList): boolean;
   public
     Host: string;
     WebClient: TNetHttpClient;
     function GetPage(AUrl: string): TNsfwXxxPostPage;
     {}
     function GetItems(
       AOut: TNsfwXXXItemList;
       AReqParam: string;
       ASearchType: TNsfwUrlType = Default;
       APageNum: integer = 1;
       Asort: TnsfwSort = Recommended;
       ATypes: TNsfwItemTypes = [Image, Video, Gallery];
       AOrientations: TNsfwOris = [Straight, Gay, Shemale, cartoons]
     ): boolean; overload;
     {}
     function GetRelatedPosts(APostUrl: string; APageNum: integer; AOut: TNsfwXxxItemList): boolean; overload;
     function GetRelatedPostsById(APostId: int64; APageNum: integer; AOut: TNsfwXXXItemList): boolean; overload;
     constructor Create;
     destructor Destroy; override;
  end;

implementation

{ TNsfwXxxScraper }

constructor TNsfwXxxScraper.Create;
begin
  inherited;
  WebClient := TNetHttpClient.Create(nil);
  Host := URL_NSFWXXX;
end;

destructor TNsfwXxxScraper.Destroy;
begin
  freeandnil(WebClient);
  inherited;
end;

function TNsfwXxxScraper.Get(AUrl: string; Aout: TNsfwXXXItemList): boolean;
var
  Response: IHTTPResponse;
  Content: string;
  n: integer;
begin
  Result := false;
  Response := WebClient.Get(Aurl);
  Content := Response.ContentAsString;
  n := Aout.Count;
  if not Content.IsEmpty then
    AOut.AddRange(ParsePosts(Content));
  if AOut.Count > n then
    Result := true;
end;

function TNsfwXxxScraper.GetPage(AUrl: string): TNsfwXxxPostPage;
var
  Response: IHTTPResponse;
  Content: string;
begin
  Response := WebClient.Get(Aurl);
  Content := Response.ContentAsString;
  Result := ParsePostPage(Content);
end;

function TNsfwXxxScraper.GetRelatedPosts(APostUrl: string; APageNum: integer;
  AOut: TNsfwXxxItemList): boolean;
var
  UniqueStr: string;
  Start, Count: integer;
begin
  Start := Pos('/post/', ApostUrl);
  Count := Pos('?', APostUrl);

  if ( Count < 1 ) then
    Count := Length(APostUrl);

  Count := ( Count - Start );
  UniqueStr := Copy(APostUrl, Start, Count);
  Result := Get(Host + UniqueStr + '/related-posts?page=' + APageNum.ToString, Aout);
end;

function TNsfwXxxScraper.GetItems(
  AOut: TNsfwXXXItemList;
  AReqParam: string;
  ASearchType: TNsfwUrlType;
  APageNum: integer;
  Asort: TnsfwSort;
  ATypes: TNsfwItemTypes;
  AOrientations: TNsfwOris): boolean;
begin
  if ( ASearchType <> Related ) then
    Result := Get(CreateUrl(ASearchtype, AReqParam, APagenum,
      ASort, Atypes, AOrientations, Host), Aout)
  else
    Result := GetRelatedPosts(AReqParam, APageNum, AOut);
end;

function TNsfwXxxScraper.GetRelatedPostsById(APostId: int64; APageNum: integer;
  Aout: TNsfwXXXItemList): boolean;
begin
  Result := Get(Host + '/post/' + inttostr(ApostId) + '/related-posts?page=' +
     Apagenum.ToString, Aout);
end;


end.
