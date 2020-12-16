// ***************************************************************************
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2020 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// Collaborators on this file:
// Jo�o Ant�nio Duarte (https://github.com/joaoduarte19)
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************** }

unit MVCFramework.RESTClient;

{$I dmvcframework.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.Mime,
  System.Net.URLClient,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  MVCFramework.Commons,
  MVCFramework.RESTClient.Indy,
  MVCFramework.RESTClient.Intf,
  MVCFramework.RESTClient.Commons,
  MVCFramework.Serializer.Intf,
  MVCFramework.Serializer.Commons,
  Data.DB;

type
  /// <summary>
  /// Alias for the Indy-based TRESTClient. The implementation of TRESTClient has been discontinued, it remains for
  /// compatibility only.
  /// </summary>
  TRESTClient = MVCFramework.RESTClient.Indy.TRESTClient deprecated
    'Moved to the MVCFramework.RESTClient.Indy unit. It is highly recommended to migrate to the TMVCRESTClient implementation.';

  IRESTResponse = MVCFramework.RESTClient.Indy.IRESTResponse deprecated
    'Moved to the MVCFramework.RESTClient.Indy unit. It is highly recommended to migrate to the TMVCRESTClient implementation.';

  TCookie = System.Net.HttpClient.TCookie;
  TCookies = System.Net.HttpClient.TCookies;
  TURLRequest = System.Net.URLClient.TURLRequest;
  TCertificate = System.Net.URLClient.TCertificate;

{$IF defined(TOKYOORBETTER)}
  THTTPSecureProtocol = System.Net.HttpClient.THTTPSecureProtocol;
  THTTPSecureProtocols = System.Net.HttpClient.THTTPSecureProtocols;
{$ENDIF}

  TMVCRESTClient = class(TInterfacedObject, IMVCRESTClient)
  private
    fHTTPClient: THTTPClient;
    fBaseURL: string;
    fResource: string;
    fAccept: string;
    fAcceptCharset: string;
    fAcceptEncoding: string;
    fUserAgent: string;
    fContentType: string;
    fAuthorization: string;
    fProxySettings: TProxySettings;
    fParameters: TList<TMVCRESTParam>;
    fRawBody: TStringStream;
    fBodyFormData: TMultipartFormData;
    fSerializer: IMVCSerializer;
    fRttiContext: TRttiContext;
    fNextRequestIsAsync: Boolean;
    fAsyncCompletionHandler: TProc<IMVCRESTResponse>;
    fAsyncCompletionHandlerWithError: TProc<Exception>;
    fAsyncSynchronized: Boolean;
    fValidateServerCertificate: TValidateServerCertificateProc;
    procedure DoValidateServerCertificate(const aSender: TObject; const aRequest: TURLRequest;
      const aCertificate: TCertificate; var aAccepted: Boolean);
    function GetBodyFormData: TMultipartFormData;
    function ObjectIsList(aObject: TObject): Boolean;
    function SerializeObject(aObject: TObject): string;
    procedure SetContentType(const aContentType: string);
    procedure SetParameter(const aParamType: TMVCRESTParamType; const aName, aValue: string);
    procedure ClearParameters(const aParamType: TMVCRESTParamType);
    function GetFullURL: string;
    function HTTPMethodName(const aHTTPMethod: TMVCHTTPMethodType): string;
    /// <summary>
    /// Convert path parameters of type ($xxx) to {xxx}
    /// </summary>
    procedure DoConvertMVCPathParamsToRESTParams(var aURL: string);
    procedure DoApplyPathParams(var aURL: string);
    procedure DoApplyQueryParams(var aURL: string);
    procedure DoApplyCookies(const aURL: string);
    procedure DoApplyHeaders;
    procedure DoEncodeURL(var aURL: string);
    procedure DoPrepareBodyRequest(var aBodyStream: TStream);

    procedure ExecuteAsyncRequest(const aMethod: TMVCHTTPMethodType);
    function InternalExecuteRequest(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse;
    function ExecuteRequest(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse;
  public
    constructor Create;
    destructor Destroy; override;

    class function New: IMVCRESTClient;

    { IMVCRESTClient }

    function BaseURL(const aBaseURL: string): IMVCRESTClient; overload;
    function BaseURL(const aHost: string; const aPort: Integer): IMVCRESTClient; overload;
    function BaseURL: string; overload;

    function ProxyServer(const aProxyServer: string): IMVCRESTClient; overload;
    function ProxyServer: string; overload;
    function ProxyPort(const aProxyPort: Integer): IMVCRESTClient; overload;
    function ProxyPort: Integer; overload;
    function ProxyUsername(const aProxyUsername: string): IMVCRESTClient; overload;
    function ProxyUsername: string; overload;
    function ProxyPassword(const aProxyPassword: string): IMVCRESTClient; overload;
    function ProxyPassword: string; overload;

{$IF defined(TOKYOORBETTER)}
    function SecureProtocols(const aSecureProtocols: THTTPSecureProtocols): IMVCRESTClient; overload;
    function SecureProtocols: THTTPSecureProtocols; overload;
{$ENDIF}

    /// <summary>
    /// Add a custom SSL certificate validation. By default all certificates are accepted.
    /// </summary>
    function SetValidateServerCertificateProc(aValidateCertificateProc: TValidateServerCertificateProc): IMVCRESTClient;

    /// <summary>
    ///   Clears all parameters (headers, body, path params and query params). This method is executed after each
    ///   request is completed.
    /// </summary>
    /// <remarks>
    ///   Cookies and authorization set in SetBasicAuthorization or SetBearerAuthorization is not removed
    /// </remarks>
    function ClearAllParams: IMVCRESTClient;

    /// <summary>
    /// Connection timeout in milliseconds to be used for the requests.
    /// </summary>
    function ConnectTimeout(const aConnectTimeout: Integer): IMVCRESTClient; overload;
    function ConnectTimeout: Integer; overload;

    /// <summary>
    /// Response reading timeout in milliseconds to be used for the requests.
    /// </summary>
    function ReadTimeout(const aReadTimeout: Integer): IMVCRESTClient; overload;
    function ReadTimeout: Integer; overload;

    /// <summary>
    /// Add basic authorization header. Authorization = Basic &lt;Username:Password&gt; (encoded in Base64)
    /// </summary>
    function SetBasicAuthorization(const aUsername, aPassword: string): IMVCRESTClient;

    /// <summary>
    /// Add bearer authorization header. Authorization = Bearer &lt;Token&gt;
    /// </summary>
    function SetBearerAuthorization(const aAccessToken: string): IMVCRESTClient;

    /// <summary>
    /// Returns the stored authorization. Includes Basic or Bearer prefix
    /// </summary>
    function Authorization: string;

    /// <summary>
    /// Removes the authorization header defined in <see cref="MVCFramework.RESTClient.Intf|IMVCRESTClient.SetBasicAuthorization(string,string)">
    /// SetBasicAuthorization</see> or <see cref="MVCFramework.RESTClient.Intf|IMVCRESTClient.SetBearerAuthorization(string)">
    /// SetBearerAuthorization</see>
    /// </summary>
    function ClearAuthorization: IMVCRESTClient;

    /// <summary>
    /// Add a header.
    /// </summary>
    /// <param name="aName">
    /// Header name
    /// </param>
    /// <param name="aValue">
    /// Header value
    /// </param>
    /// <param name="aDoNotEncode">
    /// Indicates whether the value of this header should be used as is (True), or encoded by the component (False)
    /// </param>
    function AddHeader(const aName, aValue: string): IMVCRESTClient; overload;
    function HeaderValue(const aName: string): string;

    /// <summary>
    /// Clears all headers.
    /// </summary>
    function ClearHeaders: IMVCRESTClient;

    function AllowCookies(const aAllowCookies: Boolean): IMVCRESTClient; overload;
    function AllowCookies: Boolean; overload;

    /// <summary>
    /// Add DMVC session cookie
    /// </summary>
    function SessionId(const aSessionId: string): IMVCRESTClient; overload;
    function SessionId: string; overload;

    /// <summary>
    /// Add a cookie header.
    /// </summary>
    function AddCookie(const aName, aValue: string): IMVCRESTClient;
    /// <summary>
    /// Clear all cookie headers.
    /// </summary>
    function ClearCookies: IMVCRESTClient;

    /// <summary>
    /// Add a URL segment parameter. The parameters of your url path may be enclosed in braces or in
    /// parentheses starting with a money sign. <c>/api/{param1}/($param2)</c>
    /// </summary>
    /// <param name="aName">
    /// Parameter name
    /// </param>
    /// <param name="aValue">
    /// Parameter value
    /// </param>
    function AddPathParam(const aName, aValue: string): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: Integer): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: Int64): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: TGUID): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: TDateTime): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: TDate): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: TTime): IMVCRESTClient; overload;
    function AddPathParam(const aName: string; aValue: Double): IMVCRESTClient; overload;
    function ClearPathParams: IMVCRESTClient;

    /// <summary>
    /// Add a QueryString parameter. <c>/api/person?para1=value&amp;param2=value</c>
    /// </summary>
    function AddQueryStringParam(const aName, aValue: string): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: Integer): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: Int64): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: TGUID): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: TDateTime): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: TDate): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: TTime): IMVCRESTClient; overload;
    function AddQueryStringParam(const aName: string; aValue: Double): IMVCRESTClient; overload;
    function ClearQueryParams: IMVCRESTClient;

    function Accept(const aAccept: string): IMVCRESTClient; overload;
    function Accept: string; overload;
    function AcceptCharset(const aAcceptCharset: string): IMVCRESTClient; overload;
    function AcceptCharset: string; overload;
    function AcceptEncoding(const aAcceptEncoding: string): IMVCRESTClient; overload;
    function AcceptEncoding: string; overload;
    function HandleRedirects(const aHandleRedirects: Boolean): IMVCRESTClient; overload;
    function HandleRedirects: Boolean; overload;
    function MaxRedirects(const aMaxRedirects: Integer): IMVCRESTClient; overload;
    function MaxRedirects: Integer; overload;
    function UserAgent(const aUserAgent: string): IMVCRESTClient; overload;
    function UserAgent: string; overload;

    function Resource(const aResource: string): IMVCRESTClient; overload;
    function Resource: string; overload;

    /// <summary>
    /// Add a body to the requisition.
    /// </summary>
    /// <param name="aBody">
    /// Body in string format.
    /// </param>
    /// <param name="aContentType">
    /// Body content type.
    /// </param>
    function AddBody(const aBody: string; const aContentType: string = ''): IMVCRESTClient; overload;
    /// <summary>
    /// Add a body to the requisition
    /// </summary>
    /// <param name="aBodyStream">
    /// Body in Stream format
    /// </param>
    /// <param name="aContentType">
    /// Body content type
    /// </param>
    /// <param name="aOwnsStream">
    /// If OwnsStream is true, Stream will be destroyed by IMVCRESTClient.
    /// </param>
    function AddBody(aBodyStream: TStream; const aOwnsStream: Boolean = True;
      const aContentType: string = ''): IMVCRESTClient; overload;
    /// <summary>
    /// Add a body to the requisition
    /// </summary>
    /// <param name="aBodyObject">
    /// Body in Object format. The object will be serialized to a JSON string.
    /// </param>
    /// <param name="aOwnsObject">
    /// If OwnsObject is true, BodyObject will be destroyed by IMVCRESTClient.
    /// </param>
    function AddBody(aBodyObject: TObject; const aOwnsObject: Boolean = True): IMVCRESTClient; overload;

    /// <summary>
    /// Adds a file as the request body. Several files can be added in the same request. In this case the request
    /// will be of the multipart/form-data type
    /// </summary>
    /// <param name="aName">
    /// Field name
    /// </param>
    /// <param name="aFileName">
    /// File path
    /// </param>
    /// <param name="aContentType">
    /// File content type
    /// </param>
    function AddFile(const aName, aFileName: string; const aContentType: string = ''): IMVCRESTClient; overload;
    function AddFile(const aFileName: string; const aContentType: string = ''): IMVCRESTClient; overload;

    function AddBodyFieldFormData(const aName, aValue: string): IMVCRESTClient; overload;
{$IF defined(RIOORBETTER)}
    function AddBodyFieldFormData(const aName: string; aStreamValue: TStream;
      const aContentType: string = ''): IMVCRESTClient; overload;
{$ENDIF}
    /// <summary>
    /// Add a field to the x-www-form-urlencoded body. You must set ContentType to application/x-www-form-urlencoded
    /// </summary>
    function AddBodyFieldURLEncoded(const aName, aValue: string): IMVCRESTClient;

    function ClearBody: IMVCRESTClient;

    /// <summary>
    /// Executes the next request asynchronously.
    /// </summary>
    /// <param name="aCompletionHandler">
    /// An anonymous method that will be run after the execution completed.
    /// </param>
    /// <param name="aSynchronized">
    /// Specifies if aCompletioHandler will be run in the main thread's (True) or execution thread's (False) context.
    /// </param>
    /// <param name="aCompletionHandlerWithError">
    /// An anonymous method that will be run if an exception is raised during execution.
    /// </param>
    function Async(aCompletionHandler: TProc<IMVCRESTResponse>; aCompletionHandlerWithError: TProc<Exception> = nil;
      const aSynchronized: Boolean = False): IMVCRESTClient;

    /// <summary>
    /// Execute a Get request.
    /// </summary>
    function Get(const aResource: string): IMVCRESTResponse; overload;
    function Get: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Head request.
    /// </summary>
    function Head(const aResource: string): IMVCRESTResponse; overload;
    function Head: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Options request.
    /// </summary>
    function Options(const aResource: string): IMVCRESTResponse; overload;
    function Options: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Post request.
    /// </summary>
    /// <param name="aResource">
    /// Resource path
    /// </param>
    /// <param name="aBody">
    /// Object to be serialized. It can be a simple object or a list of objects (TObjectList &lt;T&gt;)
    /// </param>
    /// <param name="aOwnsBody">
    /// If OwnsBody is true, Body will be destroyed by IMVCRESTClient. <br />
    /// </param>
    function Post(const aResource: string; aBody: TObject; const aOwnsBody: Boolean = True): IMVCRESTResponse; overload;
    function Post(const aResource: string; const aBody: string = '';
      const aContentType: string = TMVCMediaType.APPLICATION_JSON): IMVCRESTResponse; overload;
    function Post: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Patch request.
    /// </summary>
    function Patch(const aResource: string; aBody: TObject;
      const aOwnsBody: Boolean = True): IMVCRESTResponse; overload;
    function Patch(const aResource: string; const aBody: string = '';
      const aContentType: string = TMVCMediaType.APPLICATION_JSON): IMVCRESTResponse; overload;
    function Patch: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Put request.
    /// </summary>
    function Put(const aResource: string; aBody: TObject; const aOwnsBody: Boolean = True): IMVCRESTResponse; overload;
    function Put(const aResource: string; const aBody: string = '';
      const aContentType: string = TMVCMediaType.APPLICATION_JSON): IMVCRESTResponse; overload;
    function Put: IMVCRESTResponse; overload;

    /// <summary>
    /// Execute a Delete request.
    /// </summary>
    function Delete(const aResource: string): IMVCRESTResponse; overload;
    function Delete: IMVCRESTResponse; overload;

    /// <summary>
    /// Executes any type of HTTP request
    /// </summary>
    function Execute(const aMethod: TMVCHTTPMethodType; const aResource: string): IMVCRESTResponse; overload;
    function Execute(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse; overload;

    /// <summary>
    /// Serialize the current dataset record and execute a POST request.
    /// </summary>
    function DataSetInsert(const aResource: string; aDataSet: TDataSet; const aIgnoredFields: TMVCIgnoredList = [];
      const aNameCase: TMVCNameCase = ncAsIs): IMVCRESTResponse;
    /// <summary>
    /// Serialize the current dataset record and execute a PUT request.
    /// </summary>
    function DataSetUpdate(const aResource, aKeyValue: string; aDataSet: TDataSet;
      const aIgnoredFields: TMVCIgnoredList = []; const aNameCase: TMVCNameCase = ncAsIs): IMVCRESTResponse;
    /// <summary>
    /// Delete the current dataset record by executing a delete request.
    /// </summary>
    function DataSetDelete(const aResource, aKeyValue: string): IMVCRESTResponse;

    /// <summary>
    /// Register a custom serializer to the RESTClient serializer.
    /// </summary>
    function RegisterTypeSerializer(const aTypeInfo: PTypeInfo; aInstance: IMVCTypeSerializer): IMVCRESTClient;
  end;

  /// <summary>
  /// Provides access to the REST request response.
  /// </summary>
  TMVCRESTResponse = class(TInterfacedObject, IMVCRESTResponse)
  private
    fSuccess: Boolean;
    fStatusCode: Integer;
    fStatusText: string;
    fHeaders: TStrings;
    fCookies: TCookies;
    fServer: string;
    fContentType: string;
    fContentEncoding: string;
    fContentLength: Integer;
    fContent: string;
    fContentRawBytes: TBytes;

    procedure FillResponse(aHTTPResponse: IHTTPResponse);
  public
    constructor Create(aHTTPResponse: IHTTPResponse);
    destructor Destroy; override;

    { IMVCRESTResponse }
    function Success: Boolean;
    function StatusCode: Integer;
    function StatusText: string;
    function Headers: TStrings;
    function HeaderValue(const aName: string): string;
    function Cookies: TCookies;
    function CookieByName(const aName: string): TCookie;
    function Server: string;
    function ContentType: string;
    function ContentEncoding: string;
    function ContentLength: Integer;
    function Content: string;
    function ContentRawBytes: TBytes;
    procedure SaveContentToStream(aStream: TStream);
    procedure SaveContentToFile(const aFileName: string);
  end;

implementation

uses
  System.NetConsts,
  System.NetEncoding,
  MVCFramework.Serializer.JsonDataObjects,
  System.RegularExpressions;

{$IF not defined(RIOORBETTER)}
type
  TCookieManagerHelper = class helper for TCookieManager
  private
    function CookieList: TCookies;
  end;
{$ENDIF}


{ TMVCRESTClient }

function TMVCRESTClient.Accept: string;
begin
  Result := fAccept;
end;

function TMVCRESTClient.Accept(const aAccept: string): IMVCRESTClient;
begin
  Result := Self;
  fAccept := aAccept;
end;

function TMVCRESTClient.AcceptCharset: string;
begin
  Result := fAcceptCharset;
end;

function TMVCRESTClient.AcceptCharset(const aAcceptCharset: string): IMVCRESTClient;
begin
  Result := Self;
  fAcceptCharset := aAcceptCharset;
end;

function TMVCRESTClient.AcceptEncoding(const aAcceptEncoding: string): IMVCRESTClient;
begin
  Result := Self;
  fAcceptEncoding := aAcceptEncoding;
end;

function TMVCRESTClient.AcceptEncoding: string;
begin
  Result := fAcceptEncoding;
end;

function TMVCRESTClient.AddBody(const aBody: string; const aContentType: string): IMVCRESTClient;
var
  lContentCharset: string;
  lEncoding: TEncoding;
  lBytes: TArray<Byte>;
  lContentType: string;
begin
  Result := Self;

  SplitContentMediaTypeAndCharset(aContentType, lContentType, lContentCharset);

  if lContentCharset.IsEmpty then
  begin
    lContentCharset := TMVCCharSet.UTF_8;
  end;
  lEncoding := TEncoding.GetEncoding(lContentCharset);
  try
    fRawBody.Clear;

    lBytes := lEncoding.GetBytes(aBody);
    fRawBody.WriteData(lBytes, Length(lBytes));
    SetContentType(BuildContentType(lContentType, lContentCharset));
  finally
    FreeAndNil(lEncoding);
  end;
end;

function TMVCRESTClient.AddBody(aBodyStream: TStream; const aOwnsStream: Boolean;
  const aContentType: string): IMVCRESTClient;
begin
  Result := Self;

  if aBodyStream = nil then
    raise EMVCRESTClientException.Create('You need a valid body!');

  if aBodyStream is TStringStream then
    raise EMVCRESTClientException.Create('aBodyStream must be of type TStringStream!');

  SetContentType(aContentType);

  fRawBody.Clear;
  fRawBody.CopyFrom(aBodyStream, 0);

  if aOwnsStream then
    aBodyStream.Free;
end;

function TMVCRESTClient.AddBody(aBodyObject: TObject; const aOwnsObject: Boolean): IMVCRESTClient;
begin
  if aBodyObject = nil then
    raise EMVCRESTClientException.Create('You need a valid body!');

  Result := AddBody(SerializeObject(aBodyObject), TMVCMediaType.APPLICATION_JSON);

  if aOwnsObject then
    aBodyObject.Free;
end;

function TMVCRESTClient.AddBodyFieldFormData(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;
  GetBodyFormData.AddField(aName, aValue);
  SetContentType(TMVCMediaType.MULTIPART_FORM_DATA);
end;

{$IF defined(RIOORBETTER)}
function TMVCRESTClient.AddBodyFieldFormData(const aName: string; aStreamValue: TStream;
  const aContentType: string): IMVCRESTClient;
begin
  Result := Self;
  GetBodyFormData.AddStream(aName, aStreamValue, aContentType);
  SetContentType(TMVCMediaType.MULTIPART_FORM_DATA);
end;
{$ENDIF}

function TMVCRESTClient.AddBodyFieldURLEncoded(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;
  fParameters.Add(TMVCRESTParam.Create(TMVCRESTParamType.FormURLEncoded, aName, aValue));
  SetContentType(TMVCMediaType.APPLICATION_FORM_URLENCODED);
end;

function TMVCRESTClient.AddCookie(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;
  SetParameter(TMVCRESTParamType.Cookie, aName, aValue);
end;

function TMVCRESTClient.AddFile(const aFileName, aContentType: string): IMVCRESTClient;
begin
  Result := AddFile(TMVCRESTClientConsts.DEFAULT_FILE_NAME, aFileName, aContentType);
end;

function TMVCRESTClient.AddFile(const aName, aFileName, aContentType: string): IMVCRESTClient;
begin
  Result := Self;
  GetBodyFormData.AddFile(aName, aFileName {$IF defined(RIOORBETTER)}, aContentType{$ENDIF});
  SetContentType(TMVCMediaType.MULTIPART_FORM_DATA);
end;

function TMVCRESTClient.AddHeader(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;

  SetParameter(TMVCRESTParamType.Header, aName, aValue);
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: Double): IMVCRESTClient;
begin
  Result := AddPathParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddPathParam(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;
  SetParameter(TMVCRESTParamType.Path, aName, aValue);
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: TDate): IMVCRESTClient;
begin
  Result := AddPathParam(aName, DateToISODate(aValue));
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: TTime): IMVCRESTClient;
begin
  Result := AddPathParam(aName, TimeToISOTime(aValue));
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: TDateTime): IMVCRESTClient;
begin
  Result := AddPathParam(aName, DateTimeToISOTimeStamp(aValue));
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: Int64): IMVCRESTClient;
begin
  Result := AddPathParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: TGUID): IMVCRESTClient;
begin
  Result := AddPathParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddPathParam(const aName: string; aValue: Integer): IMVCRESTClient;
begin
  Result := AddPathParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: Double): IMVCRESTClient;
begin
  Result := AddPathParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: TTime): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, TimeToISOTime(aValue));
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: TDate): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, DateToISODate(aValue));
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: TDateTime): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, DateTimeToISOTimeStamp(aValue));
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: TGUID): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: Int64): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AddQueryStringParam(const aName, aValue: string): IMVCRESTClient;
begin
  Result := Self;
  SetParameter(TMVCRESTParamType.Query, aName, aValue);
end;

function TMVCRESTClient.AddQueryStringParam(const aName: string; aValue: Integer): IMVCRESTClient;
begin
  Result := AddQueryStringParam(aName, aValue.ToString);
end;

function TMVCRESTClient.AllowCookies: Boolean;
begin
  Result := fHTTPClient.AllowCookies;
end;

function TMVCRESTClient.AllowCookies(const aAllowCookies: Boolean): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.AllowCookies := aAllowCookies;
end;

function TMVCRESTClient.Async(aCompletionHandler: TProc<IMVCRESTResponse>;
  aCompletionHandlerWithError: TProc<Exception>; const aSynchronized: Boolean): IMVCRESTClient;
begin
  Result := Self;
  fNextRequestIsAsync := True;
  fAsyncCompletionHandler := aCompletionHandler;
  fAsyncCompletionHandlerWithError := aCompletionHandlerWithError;
  fAsyncSynchronized := aSynchronized;
end;

function TMVCRESTClient.Authorization: string;
begin
  Result := fAuthorization;
end;

function TMVCRESTClient.BaseURL(const aBaseURL: string): IMVCRESTClient;
begin
  Result := Self;

  fBaseURL := aBaseURL;
  if not fBaseURL.Contains('://') then
    fBaseURL := 'http://' + fBaseURL;

  fBaseURL := fBaseURL;
end;

function TMVCRESTClient.BaseURL(const aHost: string; const aPort: Integer): IMVCRESTClient;
begin
  Result := BaseURL(aHost + ':' + aPort.ToString);
end;

function TMVCRESTClient.BaseURL: string;
begin
  Result := fBaseURL;
end;

function TMVCRESTClient.ClearAllParams: IMVCRESTClient;
begin
  Result := Self;
  fParameters.Clear;
  ClearBody;

  fNextRequestIsAsync := False;
  fAsyncCompletionHandler := nil;
  fAsyncCompletionHandlerWithError := nil;
  fAsyncSynchronized := False;
end;

function TMVCRESTClient.ClearAuthorization: IMVCRESTClient;
begin
  Result := Self;
  fAuthorization := '';
end;

function TMVCRESTClient.ClearBody: IMVCRESTClient;
begin
  fRawBody.Clear;
  if Assigned(fBodyFormData) then
    FreeAndNil(fBodyFormData);

  Result := Self;
  ClearParameters(TMVCRESTParamType.FormURLEncoded);
  fContentType := '';
end;


function TMVCRESTClient.ClearCookies: IMVCRESTClient;
begin
  Result := Self;
  ClearParameters(TMVCRESTParamType.Cookie);
{$IF defined(RIOORBETTER)}
  fHTTPClient.CookieManager.Clear;
{$ELSE}
  if fHTTPClient.CookieManager.CookieList <> nil then
    fHTTPClient.CookieManager.CookieList.Clear;
{$ENDIF}
end;

function TMVCRESTClient.ClearHeaders: IMVCRESTClient;
begin
  Result := Self;
  ClearParameters(TMVCRESTParamType.Header);
end;

procedure TMVCRESTClient.ClearParameters(const aParamType: TMVCRESTParamType);
var
  I: Integer;
begin
  for I := Pred(fParameters.Count) downto 0 do
  begin
    if fParameters[I].&Type = aParamType then
      fParameters.Delete(I);
  end;
end;

function TMVCRESTClient.ClearPathParams: IMVCRESTClient;
begin
  Result := Self;
  ClearParameters(TMVCRESTParamType.Path);
end;

function TMVCRESTClient.ClearQueryParams: IMVCRESTClient;
begin
  Result := Self;
  ClearParameters(TMVCRESTParamType.Query);
end;

function TMVCRESTClient.ConnectTimeout: Integer;
begin
  Result := fHTTPClient.ConnectionTimeout;
end;

function TMVCRESTClient.ConnectTimeout(const aConnectTimeout: Integer): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.ConnectionTimeout := aConnectTimeout;
end;

constructor TMVCRESTClient.Create;
begin
  inherited Create;

  fHTTPClient := THTTPClient.Create;
  fHTTPClient.OnValidateServerCertificate := DoValidateServerCertificate;
  fHTTPClient.HandleRedirects := True;
  fHTTPClient.MaxRedirects := TMVCRESTClientConsts.DEFAULT_MAX_REDIRECTS;
{$IF defined(TOKYOORBETTER)}
  fHTTPClient.SecureProtocols := CHTTPDefSecureProtocols;
{$ENDIF}

  fValidateServerCertificate := nil;
  fParameters := TList<TMVCRESTParam>.Create;
  fRawBody := TStringStream.Create;
  fBodyFormData := nil;
  fSerializer := TMVCJsonDataObjectsSerializer.Create;
  fRttiContext := TRttiContext.Create;
  fProxySettings := TProxySettings.Create('', 0);
  fBaseURL := '';
  fResource := '';

  fAccept := TMVCRESTClientConsts.DEFAULT_ACCEPT;
  fAcceptCharset := '';
  fAcceptEncoding := TMVCRESTClientConsts.DEFAULT_ACCEPT_ENCODING;
  fUserAgent := TMVCRESTClientConsts.DEFAULT_USER_AGENT;
  fContentType := '';
  fAuthorization := '';

  ClearAllParams;
end;

function TMVCRESTClient.DataSetDelete(const aResource, aKeyValue: string): IMVCRESTResponse;
var
  lResource: string;
begin
  lResource := aResource;
  if not aKeyValue.IsEmpty then
  begin
    lResource := aResource + '/' + aKeyValue;
  end;
  Result := Delete(lResource);
end;

function TMVCRESTClient.DataSetInsert(const aResource: string; aDataSet: TDataSet;
  const aIgnoredFields: TMVCIgnoredList; const aNameCase: TMVCNameCase): IMVCRESTResponse;
begin
  Result := Post(aResource, fSerializer.SerializeDataSetRecord(aDataSet, aIgnoredFields, aNameCase));
end;

function TMVCRESTClient.DataSetUpdate(const aResource, aKeyValue: string; aDataSet: TDataSet;
  const aIgnoredFields: TMVCIgnoredList; const aNameCase: TMVCNameCase): IMVCRESTResponse;
var
  lResource: string;
begin
  lResource := aResource;
  if not aKeyValue.IsEmpty then
  begin
    lResource := aResource + '/' + aKeyValue;
  end;

  Result := Put(lResource, fSerializer.SerializeDataSetRecord(aDataSet, aIgnoredFields, aNameCase));
end;

function TMVCRESTClient.Delete(const aResource: string): IMVCRESTResponse;
begin
  Resource(aResource);
  Result := Delete;
end;

function TMVCRESTClient.Delete: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpDELETE);
end;

destructor TMVCRESTClient.Destroy;
begin
  FreeAndNil(fHTTPClient);
  FreeAndNil(fParameters);

  if Assigned(fBodyFormData) then
    FreeAndNil(fBodyFormData);
  FreeAndNil(fRawBody);

  fSerializer := nil;
  fRttiContext.Free;
  inherited;
end;

procedure TMVCRESTClient.DoApplyCookies(const aURL: string);
var
  lParam: TMVCRESTParam;
  lName: string;
  lValue: string;
begin
  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Cookie then
    begin
      lName := TMVCRESTClientHelper.URIEncode(lParam.Name);
      lValue := TMVCRESTClientHelper.URIEncode(lParam.Value);
      fHTTPClient.CookieManager.AddServerCookie(lName + '=' + lValue, aURL);
    end;
  end;
end;

{$IF not defined(SYDNEYORBETTER)}
type
  THackURLClient = class(TURLClient);
{$ENDIF}

procedure TMVCRESTClient.DoApplyHeaders;
var
  lParam: TMVCRESTParam;
begin
{$IF defined(SYDNEYORBETTER)}
  fHTTPClient.CustHeaders.Clear;
{$ELSE}
  SetLength(THackURLClient(fHTTPClient).FCustomHeaders, 0);
{$ENDIF}

  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Header then
    begin
      fHTTPClient.CustomHeaders[lParam.Name] := lParam.Value;
    end;
  end;
  if not fAuthorization.IsEmpty then
  begin
    fHTTPClient.CustomHeaders[TMVCRESTClientConsts.AUTHORIZATION_HEADER] := fAuthorization;
  end;
  fHTTPClient.Accept := fAccept;
  fHTTPClient.AcceptCharSet := fAcceptCharset;
  fHTTPClient.AcceptEncoding := fAcceptEncoding;
  fHTTPClient.ContentType := fContentType;
end;

procedure TMVCRESTClient.DoApplyPathParams(var aURL: string);
var
  lParam: TMVCRESTParam;
  lReplace: string;
  lEncodedParam: string;
begin
  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Path then
    begin
      lReplace := '{' + lParam.Name + '}';
      lEncodedParam := TNetEncoding.URL.Encode(lParam.Value, TMVCRESTClientConsts.PATH_UNSAFE_CHARS,
        [TURLEncoding.TEncodeOption.EncodePercent]);
      aURL := aURL.Replace(lReplace, lEncodedParam, [rfReplaceAll, rfIgnoreCase]);
    end;
  end;
end;

procedure TMVCRESTClient.DoApplyQueryParams(var aURL: string);
var
  lParam: TMVCRESTParam;
  lName: string;
  lValue: string;
  lConcat: string;
begin
  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Query then
    begin
      lName := TMVCRESTClientHelper.URIEncode(lParam.Name);
      lValue := TNetEncoding.URL.EncodeForm(lParam.Value);

      if aURL.Contains('?') then
        lConcat := '&'
      else
        lConcat := '?';

      aURL := aURL + lConcat + lName + '=' + lValue;
    end;
  end;
end;

procedure TMVCRESTClient.DoConvertMVCPathParamsToRESTParams(var aURL: string);
begin
  aURL := TRegEx.Replace(aURL, '(\([($])([\w_]+)([)])', '{\2}', [TRegExOption.roIgnoreCase]);
end;

procedure TMVCRESTClient.DoEncodeURL(var aURL: string);
begin
  // It is necessary to encode the dots because the HTTPClient removes dotted URL segments.
  // See https://tools.ietf.org/html/rfc3986#section-5.2.4
  aURL := aURL.Replace('\', '/', [rfReplaceAll]);
  aURL := aURL.Replace('../', '%2E%2E/', [rfReplaceAll]);
  aURL := aURL.Replace('./', '%2E/', [rfReplaceAll]);


{$IF defined(RIOORBETTER)}
  aURL := TURI.Create(aURL).Encode;
{$ELSE}
  aURL := TURI.Create(aURL).ToString;
{$ENDIF}
end;

procedure TMVCRESTClient.DoPrepareBodyRequest(var aBodyStream: TStream);
var
  lContentType: string;
  lContentCharset: string;
  lParam: TMVCRESTParam;
  lName: string;
  lValue: string;
  lBody: string;
begin
  SplitContentMediaTypeAndCharset(fContentType, lContentType, lContentCharset);

  if SameText(lContentType, TMVCMediaType.MULTIPART_FORM_DATA) then
  begin
    aBodyStream := GetBodyFormData.Stream;
    SetContentType(GetBodyFormData.MimeTypeHeader);
  end
  else if SameText(lContentType, TMVCMediaType.APPLICATION_FORM_URLENCODED) then
  begin
    lBody := '';
    for lParam in fParameters do
    begin
      if lParam.&Type = TMVCRESTParamType.FormURLEncoded then
      begin
        lName := TMVCRESTClientHelper.URIEncode(lParam.Name);
        lValue := TNetEncoding.URL.EncodeForm(lParam.Value);
        if not lBody.IsEmpty then
          lBody := lBody + '&';
        lBody := lBody + lName + '=' + lValue;
      end;
    end;
    AddBody(lBody, fContentType);
    aBodyStream := fRawBody;
  end
  else
  begin
    aBodyStream := fRawBody;
  end;
  aBodyStream.Position := 0;
end;

function TMVCRESTClient.Execute(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse;
begin
  Result := ExecuteRequest(aMethod);
end;

function TMVCRESTClient.Execute(const aMethod: TMVCHTTPMethodType; const aResource: string): IMVCRESTResponse;
begin
  Resource(aResource);
  Result := Execute(aMethod);
end;

procedure TMVCRESTClient.ExecuteAsyncRequest(const aMethod: TMVCHTTPMethodType);
var
  lThread: TThread;
  lRESTClient: IMVCRESTClient;
begin
  // This is necessary for the thread to be able to access the RESTClient fields
  lRESTClient := Self;
  lThread := TThread.CreateAnonymousThread(
    procedure
    var
      lResponse: IMVCRESTResponse;
    begin
      try
        lResponse := TMVCRESTClient(lRESTClient).InternalExecuteRequest(aMethod);
        TMonitor.Enter(TObject(lResponse));
        try
          if Assigned(fAsyncCompletionHandler) then
          begin
            if fAsyncSynchronized then
            begin
              TThread.Synchronize(nil,
                procedure
                begin
                  fAsyncCompletionHandler(lResponse);
                end
                );
            end
            else
            begin
              fAsyncCompletionHandler(lResponse);
            end;
          end;
        finally
          TMonitor.Exit(TObject(lResponse));
        end;
      except
        on E: Exception do
        begin
          if Assigned(fAsyncCompletionHandlerWithError) then
          begin
            if fAsyncSynchronized then
            begin
              TThread.Synchronize(nil,
                procedure
                begin
                  fAsyncCompletionHandlerWithError(E);
                end
                );
            end
            else
            begin
              fAsyncCompletionHandlerWithError(E);
            end;
          end;
        end;
      end;
      ClearAllParams;
    end
    );
  lThread.Start;
end;

function TMVCRESTClient.ExecuteRequest(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse;
begin
  if fNextRequestIsAsync then
  begin
    Result := nil;
    ExecuteAsyncRequest(aMethod);
  end
  else
  begin
    Result := InternalExecuteRequest(aMethod);
    ClearAllParams;
  end;
end;

function TMVCRESTClient.Get: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpGET);
end;

function TMVCRESTClient.GetBodyFormData: TMultipartFormData;
begin
  if not Assigned(fBodyFormData) then
  begin
    fBodyFormData := TMultipartFormData.Create;
  end;
  Result := fBodyFormData;
end;

function TMVCRESTClient.GetFullURL: string;
var
  lResource: string;
begin
  Result := fBaseURL;

  lResource := fResource;
  if not lResource.IsEmpty then
  begin
    if not Result.EndsWith('/') and
      not (lResource.StartsWith('/') or lResource.StartsWith('?') or lResource.StartsWith('#')) then
    begin
      Result := Result + '/';
    end;

    Result := Result + lResource;
  end;
end;

function TMVCRESTClient.Get(const aResource: string): IMVCRESTResponse;
begin
  Resource(aResource);
  Result := ExecuteRequest(TMVCHTTPMethodType.httpGET);
end;

function TMVCRESTClient.HandleRedirects(const aHandleRedirects: Boolean): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.HandleRedirects := aHandleRedirects;
end;

function TMVCRESTClient.HandleRedirects: Boolean;
begin
  Result := fHTTPClient.HandleRedirects;
end;

function TMVCRESTClient.Head: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpHEAD);
end;

function TMVCRESTClient.Head(const aResource: string): IMVCRESTResponse;
begin
  Resource(aResource);
  Result := Head;
end;

function TMVCRESTClient.HeaderValue(const aName: string): string;
var
  lParam: TMVCRESTParam;
begin
  Result := '';

  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Header then
    begin
      if SameText(lParam.Name, aName) then
        Exit(lParam.Value);
    end;
  end;
end;

function TMVCRESTClient.HTTPMethodName(const aHTTPMethod: TMVCHTTPMethodType): string;
begin
  case aHTTPMethod of
    httpGET:
      Result := 'GET';
    httpPOST:
      Result := 'POST';
    httpPUT:
      Result := 'PUT';
    httpDELETE:
      Result := 'DELETE';
    httpHEAD:
      Result := 'HEAD';
    httpOPTIONS:
      Result := 'OPTIONS';
    httpPATCH:
      Result := 'PATCH';
    httpTRACE:
      Result := 'TRACE';
  end;
end;

function TMVCRESTClient.InternalExecuteRequest(const aMethod: TMVCHTTPMethodType): IMVCRESTResponse;
var
  lURL: string;
  lResponse: IHTTPResponse;
  lBodyStream: TStream;
  lURI: TURI;
  lRequest: IHTTPRequest;
begin
  fHTTPClient.ProxySettings := fProxySettings;

  lURL := GetFullURL;
  DoConvertMVCPathParamsToRESTParams(lURL);
  DoApplyPathParams(lURL);
  DoApplyQueryParams(lURL);
  DoEncodeURL(lURL);
  DoApplyCookies(lURL);
  lURI := TURI.Create(lURL);

  lBodyStream := nil;
  DoPrepareBodyRequest(lBodyStream);
  DoApplyHeaders;

  lRequest := fHTTPClient.GetRequest(HTTPMethodName(aMethod), lURI);
  lRequest.SourceStream := lBodyStream;
  lResponse := fHTTPClient.Execute(lRequest, nil, []);

  Result := TMVCRESTResponse.Create(lResponse);
end;

function TMVCRESTClient.MaxRedirects(const aMaxRedirects: Integer): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.MaxRedirects := aMaxRedirects;
end;

function TMVCRESTClient.MaxRedirects: Integer;
begin
  Result := fHTTPClient.MaxRedirects;
end;

class function TMVCRESTClient.New: IMVCRESTClient;
begin
  Result := TMVCRESTClient.Create;
end;

function TMVCRESTClient.ObjectIsList(aObject: TObject): Boolean;
begin
  Result := fRttiContext.GetType(aObject.ClassType).GetMethod('GetEnumerator') <> nil;
end;

function TMVCRESTClient.Options: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpOPTIONS);
end;

function TMVCRESTClient.Options(const aResource: string): IMVCRESTResponse;
begin
  Resource(aResource);
  Result := Options;
end;

procedure TMVCRESTClient.DoValidateServerCertificate(const aSender: TObject; const aRequest: TURLRequest;
  const aCertificate: TCertificate; var aAccepted: Boolean);
begin
  if Assigned(fValidateServerCertificate) then
    fValidateServerCertificate(aSender, aRequest, aCertificate, aAccepted)
  else
    aAccepted := True;
end;

function TMVCRESTClient.Patch(const aResource, aBody: string; const aContentType: string): IMVCRESTResponse;
begin
  Resource(aResource);
  if not aBody.isEmpty then
  begin
    ClearBody;
    AddBody(aBody, aContentType);
  end;

  Result := Patch;
end;

function TMVCRESTClient.Patch: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpPATCH);
end;

function TMVCRESTClient.Patch(const aResource: string; aBody: TObject; const aOwnsBody: Boolean): IMVCRESTResponse;
begin
  if aBody = nil then
    raise EMVCRESTClientException.Create('You need a valid body!');

  Result := Patch(aResource, SerializeObject(aBody));

  if aOwnsBody then
    aBody.Free;
end;

function TMVCRESTClient.Post(const aResource, aBody, aContentType: string): IMVCRESTResponse;
begin
  Resource(aResource);
  if not aBody.IsEmpty then
  begin
    ClearBody;
    AddBody(aBody, aContentType);
  end;
  Result := Post;
end;

function TMVCRESTClient.Post(const aResource: string; aBody: TObject; const aOwnsBody: Boolean): IMVCRESTResponse;
begin
  if aBody = nil then
    raise EMVCRESTClientException.Create('You need a valid body!');

  Result := Post(aResource, SerializeObject(aBody));

  if aOwnsBody then
    aBody.Free;
end;

function TMVCRESTClient.Post: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpPOST);
end;

function TMVCRESTClient.ProxyPassword: string;
begin
  Result := fProxySettings.Password;
end;

function TMVCRESTClient.ProxyPassword(const aProxyPassword: string): IMVCRESTClient;
begin
  Result := Self;
  fProxySettings.Password := aProxyPassword;
end;

function TMVCRESTClient.ProxyPort: Integer;
begin
  Result := fProxySettings.Port;
end;

function TMVCRESTClient.ProxyPort(const aProxyPort: Integer): IMVCRESTClient;
begin
  Result := Self;
  fProxySettings.Port := aProxyPort;
end;

function TMVCRESTClient.ProxyServer(const aProxyServer: string): IMVCRESTClient;
begin
  Result := Self;
  fProxySettings.Host := aProxyServer;
end;

function TMVCRESTClient.ProxyServer: string;
begin
  Result := fProxySettings.Host;
end;

function TMVCRESTClient.ProxyUsername(const aProxyUsername: string): IMVCRESTClient;
begin
  Result := Self;
  fProxySettings.UserName := aProxyUsername;
end;

function TMVCRESTClient.ProxyUsername: string;
begin
  Result := fProxySettings.UserName;
end;

function TMVCRESTClient.Put: IMVCRESTResponse;
begin
  Result := ExecuteRequest(TMVCHTTPMethodType.httpPUT);
end;

function TMVCRESTClient.Put(const aResource, aBody, aContentType: string): IMVCRESTResponse;
begin
  Resource(aResource);
  if not aBody.IsEmpty then
  begin
    ClearBody;
    AddBody(aBody, aContentType);
  end;
  Result := Put;
end;

function TMVCRESTClient.Put(const aResource: string; aBody: TObject; const aOwnsBody: Boolean): IMVCRESTResponse;
begin
  if aBody = nil then
    raise EMVCRESTClientException.Create('You need a valid body!');

  Result := Put(aResource, SerializeObject(aBody));

  if aOwnsBody then
    aBody.Free;
end;

function TMVCRESTClient.ReadTimeout: Integer;
begin
  Result := fHTTPClient.ResponseTimeout;
end;

function TMVCRESTClient.ReadTimeout(const aReadTimeout: Integer): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.ResponseTimeout := aReadTimeout;
end;

function TMVCRESTClient.RegisterTypeSerializer(const aTypeInfo: PTypeInfo;
aInstance: IMVCTypeSerializer): IMVCRESTClient;
begin
  Result := Self;
  fSerializer.RegisterTypeSerializer(aTypeInfo, aInstance);
end;

function TMVCRESTClient.Resource(const aResource: string): IMVCRESTClient;
begin
  Result := Self;
  fResource := aResource;
end;

function TMVCRESTClient.Resource: string;
begin
  Result := fResource;
end;

{$IF defined(TOKYOORBETTER)}


function TMVCRESTClient.SecureProtocols: THTTPSecureProtocols;
begin
  Result := fHTTPClient.SecureProtocols;
end;

function TMVCRESTClient.SecureProtocols(const aSecureProtocols: THTTPSecureProtocols): IMVCRESTClient;
begin
  Result := Self;
  fHTTPClient.SecureProtocols := aSecureProtocols;
end;
{$ENDIF}


function TMVCRESTClient.SerializeObject(aObject: TObject): string;
begin
  if ObjectIsList(aObject) then
    Result := fSerializer.SerializeCollection(aObject)
  else
    Result := fSerializer.SerializeObject(aObject);
end;

function TMVCRESTClient.SessionId: string;
var
  lCookie: TCookie;
  lParam: TMVCRESTParam;
begin
  Result := '';

  for lParam in fParameters do
  begin
    if lParam.&Type = TMVCRESTParamType.Cookie then
    begin
      if SameText(lParam.Name, TMVCConstants.SESSION_TOKEN_NAME) then
      begin
        Result := lParam.Value;
        Break;
      end;
    end;
  end;

  if Result.IsEmpty then
  begin
    for lCookie in fHTTPClient.CookieManager.Cookies do
    begin
      if SameText(lCookie.Name, TMVCConstants.SESSION_TOKEN_NAME) then
      begin
        Result := lCookie.Value;
        Break;
      end;
    end;
    Result := lCookie.Value;
  end;

  if Result.Contains('invalid') then
    Result := '';
end;

function TMVCRESTClient.SessionId(const aSessionId: string): IMVCRESTClient;
begin
  Result := Self;

  AddCookie(TMVCConstants.SESSION_TOKEN_NAME, aSessionId);
end;

function TMVCRESTClient.SetBasicAuthorization(const aUsername, aPassword: string): IMVCRESTClient;
var
  lBase64: TNetEncoding;
begin
  Result := Self;
  // Do not use TNetEncoding.Base64 here, because it may break long line
  lBase64 := TBase64Encoding.Create(0, '');
  try
    fAuthorization := TMVCRESTClientConsts.BASIC_AUTH_PREFIX + lBase64.Encode(aUsername + ':' + aPassword);
  finally
    FreeAndNil(lBase64);
  end;
end;

function TMVCRESTClient.SetBearerAuthorization(const aAccessToken: string): IMVCRESTClient;
begin
  Result := Self;
  fAuthorization := TMVCRESTClientConsts.BEARER_AUTH_PREFIX + aAccessToken;
end;

procedure TMVCRESTClient.SetContentType(const aContentType: string);
begin
  fContentType := aContentType;
end;

procedure TMVCRESTClient.SetParameter(const aParamType: TMVCRESTParamType; const aName, aValue: string);
var
  I: Integer;
begin
  for I := Pred(fParameters.Count) downto 0 do
  begin
    if (fParameters[I].&Type = aParamType) and SameText(fParameters[I].Name, aName) then
    begin
      fParameters.Delete(I);
      Break;
    end;
  end;

  fParameters.Add(TMVCRESTParam.Create(aParamType, aName, aValue));
end;

function TMVCRESTClient.SetValidateServerCertificateProc(
  aValidateCertificateProc: TValidateServerCertificateProc): IMVCRESTClient;
begin
  Result := Self;
  fValidateServerCertificate := aValidateCertificateProc;
end;

function TMVCRESTClient.UserAgent(const aUserAgent: string): IMVCRESTClient;
begin
  Result := Self;
  fUserAgent := aUserAgent;
end;

function TMVCRESTClient.UserAgent: string;
begin
  Result := fUserAgent;
end;

{ TMVCRESTResponse }

function TMVCRESTResponse.Content: string;
begin
  Result := fContent;
end;

function TMVCRESTResponse.ContentEncoding: string;
begin
  Result := fContentEncoding;
end;

function TMVCRESTResponse.ContentLength: Integer;
begin
  Result := fContentLength;
end;

function TMVCRESTResponse.ContentType: string;
begin
  Result := fContentType;
end;

function TMVCRESTResponse.CookieByName(const aName: string): TCookie;
var
  lCookie: TCookie;
begin
  Result := Default (TCookie);
  for lCookie in fCookies do
  begin
    if SameText(lCookie.Name, aName) then
      Exit(lCookie);
  end;
end;

function TMVCRESTResponse.Cookies: TCookies;
begin
  Result := fCookies;
end;

constructor TMVCRESTResponse.Create(aHTTPResponse: IHTTPResponse);
begin
  fHeaders := TStringList.Create;
  SetLength(fContentRawBytes, 0);
  fCookies := TCookies.Create;

  FillResponse(aHTTPResponse);
end;

destructor TMVCRESTResponse.Destroy;
begin
  SetLength(fContentRawBytes, 0);
  FreeAndNil(fHeaders);
  FreeAndNil(fCookies);
  inherited Destroy;
end;

procedure TMVCRESTResponse.FillResponse(aHTTPResponse: IHTTPResponse);
var
  lHeader: TNetHeader;
begin
  fSuccess := (aHTTPResponse.StatusCode >= 200) and (aHTTPResponse.StatusCode < 300);
  fStatusCode := aHTTPResponse.StatusCode;
  fStatusText := aHTTPResponse.StatusText;

  for lHeader in aHTTPResponse.Headers do
  begin
    fHeaders.Values[lHeader.Name] := lHeader.Value;
  end;
  fCookies.AddRange(aHTTPResponse.Cookies.ToArray);
  fServer := aHTTPResponse.HeaderValue[TMVCRESTClientConsts.SERVER_HEADER];
  fContentRawBytes := TMVCRESTClientHelper.GetResponseContentAsRawBytes(aHTTPResponse.ContentStream,
    aHTTPResponse.ContentEncoding);
  fContent := TMVCRESTClientHelper.GetResponseContentAsString(fContentRawBytes, aHTTPResponse.HeaderValue[sContentType]);
  fContentType := aHTTPResponse.HeaderValue[sContentType];
  fContentEncoding := aHTTPResponse.ContentEncoding;
  fContentLength := aHTTPResponse.ContentLength;
end;

function TMVCRESTResponse.Headers: TStrings;
begin
  Result := fHeaders;
end;

function TMVCRESTResponse.HeaderValue(const aName: string): string;
begin
  Result := fHeaders.Values[aName];
end;

function TMVCRESTResponse.ContentRawBytes: TBytes;
begin
  Result := fContentRawBytes;
end;

procedure TMVCRESTResponse.SaveContentToFile(const aFileName: string);
var
  lStream: TMemoryStream;
begin
  lStream := TMemoryStream.Create;
  try
    lStream.Write(fContentRawBytes, Length(fContentRawBytes));
    lStream.Position := 0;
    lStream.SaveToFile(aFileName);
  finally
    FreeAndNil(lStream);
  end;
end;

procedure TMVCRESTResponse.SaveContentToStream(aStream: TStream);
begin
  if aStream = nil then
    raise EMVCRESTClientException.Create('Stream not assigned!');

  aStream.Write(fContentRawBytes, Length(fContentRawBytes));
end;

function TMVCRESTResponse.Server: string;
begin
  Result := fServer;
end;

function TMVCRESTResponse.StatusCode: Integer;
begin
  Result := fStatusCode;
end;

function TMVCRESTResponse.StatusText: string;
begin
  Result := fStatusText;
end;

function TMVCRESTResponse.Success: Boolean;
begin
  Result := fSuccess;
end;

{$IF not defined(RIOORBETTER)}

{ TCookieManagerHelper }

function TCookieManagerHelper.CookieList: TCookies;
var
  lRttiContext: TRttiContext;
  lField: TRttiField;
begin
  lRttiContext := TRttiContext.Create;
  try
    lField := lRttiContext.GetType(Self.ClassType).GetField('FCookies');
    Result := nil;
    if Assigned(lField) then
      Result := lField.GetValue(Self).AsObject as TCookies;
  finally
    lRttiContext.Free;
  end;
end;

{$ENDIF}

end.
