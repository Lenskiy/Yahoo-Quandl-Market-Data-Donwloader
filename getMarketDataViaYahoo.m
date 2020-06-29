function data = getMarketDataViaYahoo(symbol, startdate, enddate, interval)
    % Downloads market data from Yahoo Finance for a specified symbol and 
    % time range.
    % 
    % INPUT:
    % symbol    - is a ticker symbol i.e. 'AMD', 'BTC-USD'
    % startdate - the date from which the market data will be requested
    % enddate   - the market data will be requested till this date
    % interval  - the market data will be returned in this intervals
    % supported intervals are '1d', '5d', '1wk', '1mo', '3mo'
    %
	% OUTPUT:
    % data - is a retrieved  dataset returned as a table
    %
    % Example: 
    %   data = getMarketDataViaYahoo('AMD', '1-Jan-2018', datetime('today'), '5d');
    % 
    % Author: Artem Lenskiy, PhD
    % Version: 0.932
    %
    % Special thanks to Patryk Dwórznik (https://github.com/dworznik) for
    % a hint on JavaScript processing. 
    %
    % Alternative approach is given here
    % https://stackoverflow.com/questions/50813539/user-agent-cookie-workaround-to-web-scraping-in-matlab
    %
    % Another approach taken form WFAToolbox is to send a post request as
    % follows:
    % urlread(url, 'post',{'matlabstockdata@yahoo.com', 'historical stocks'})
    
    if(nargin() == 1)
        startdate = posixtime(datetime('1-Jan-2018'));
        enddate = posixtime(datetime()); % now
        interval = '1d';
    elseif (nargin() == 2)
        startdate = posixtime(datetime(startdate));
        enddate = posixtime(datetime()); % now
        interval = '1d';
    elseif (nargin() == 3)
        startdate = posixtime(datetime(startdate));
        enddate = posixtime(datetime(enddate));        
        interval = '1d';
    elseif(nargin() == 4)
        startdate = posixtime(datetime(startdate));
        enddate = posixtime(datetime(enddate));
    else
        error('At least one parameter is required. Specify ticker symbol.');
        data = [];
        return;
    end
    
    %% Construct an URL to obtain the crumb value that is linked to the session cookie. 
    % It could be important to request data for the same range, however to
    % save bandwidth and time, request data for one day.
    uri = matlab.net.URI(['https://finance.yahoo.com/quote/', upper(symbol), '/history'],...
        'period1',  num2str(uint64(posixtime(datetime()-5)), '%.10g'),...
        'period2',  num2str(uint64(posixtime(datetime())), '%.10g'),...
        'interval', interval,...
        'filter', 'history',...
        'frequency', interval,...
        'guccounter', 1);

    options = matlab.net.http.HTTPOptions('ConnectTimeout', 20, 'DecodeResponse', 1, 'Authenticate', 0, 'ConvertResponse', 0);
    %% Extract the crumb value 
    % The ideas is taken from here:
    % http://blog.bradlucas.com/posts/2017-06-02-new-yahoo-finance-quote-download-url/
    % The while loop is used to make sure that generated crumb value does
    % not contains '\', since requestObj.send does not correctly send URLs
    % with slash
    crumb = "\";
    while(contains(crumb, '\'))
        requestObj = matlab.net.http.RequestMessage();
        [response, ~, ~]  = requestObj.send(uri, options);
        ind = regexp(response.Body.Data, '"CrumbStore":{"crumb":"(.*?)"}');
        if(isempty(ind))
            crumb = [];
            break;
            %error(['Possibly ', symbol ,' is not found']);
        else
            crumb = response.Body.Data.extractBetween(ind(1)+23, ind(1)+33);
        end
    end
    
    %% Find the session cookie
    % The idea is taken from here:
    % https://stackoverflow.com/questions/40090191/sending-session-cookie-with-each-subsequent-http-request-in-matlab?rq=1

    % It is important: 
    %       (1) to add session cookie that matches crumb values;
    %       (2) specify UserAgent
    
    setCookieFields = response.getFields('Set-Cookie');
    setContentFields = response.getFields('Content-Type');
    if ~isempty(setCookieFields)
       cookieInfos = setCookieFields.convert(uri);
       contentInfos = setContentFields.convert();
       requestObj = requestObj.addFields(matlab.net.http.field.CookieField([cookieInfos.Cookie]));
       requestObj = requestObj.addFields(matlab.net.http.field.ContentTypeField(contentInfos));
       requestObj = requestObj.addFields(matlab.net.http.field.GenericField('User-Agent', 'Mozilla/5.0'));
    else
        disp('Check ticker symbol and that Yahoo provides data for it');
        data = [];
        return;
    end
 
    %% Send a request for data
    % Construct an URL for the specific data
    uri = matlab.net.URI(['https://query1.finance.yahoo.com/v7/finance/download/', upper(symbol) ],...
        'period1',  num2str(uint64(startdate), '%.10g'),...
        'period2',  num2str(uint64(enddate), '%.10g'),...
        'interval', interval,...
        'events',   'history',...
        'crumb',    crumb,...
        'literal');  
    
    options = matlab.net.http.HTTPOptions('ConnectTimeout', 20,...
        'DecodeResponse', 1, 'Authenticate', 0, 'ConvertResponse', 0);

    [response, ~, ~]  = requestObj.send(uri, options);
    if(~strcmp(response.StatusCode, 'OK'))
        disp('No data available');
        data = [];
    else
        data = formTableYahoo(response.Body.Data);
    end
end

%% Convert data to the table format
function procData = formTableYahoo(data)
    records = data.splitlines;
    header = records(1).split(',');
    content = zeros(size(records, 1) - 1, size(header, 1) - 1);
    for k = 1:size(records, 1) - 1
        items = records(k + 1).split(',');
        dates(k) = datetime(items(1));
        for l = 2:size(header, 1)
            content(k, l - 1) = str2double(items(l));
        end
    end
    % Some tables contain 'null' values in certain rows, that are converted
    % to NaN by str2double. Such rows needs to be removed.
    remInds = find(sum(isnan(content), 2) == 6);
    content(remInds, :) = [];
    dates(remInds) = [];    
    % create a table
	procData = table(dates', content(:,1), content(:,2),... 
            content(:,3), content(:,4), content(:,5),...
            content(:,6));
    for k = 1:size(header, 1)    
         procData.Properties.VariableNames{k} = char(header(k).replace(' ', ''));  
    end
end
