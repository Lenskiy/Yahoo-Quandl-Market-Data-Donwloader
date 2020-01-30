function data = getMarketDataViaYahooU(symbol, startdate, enddate, interval)
    % Downloads market data from Yahoo Finance for a specified symbol and 
    % time range.
    % --------------------------------------------------------------------
    % This implementation requires a nonstandard urlread2 function
    % --------------------------------------------------------------------
    % INPUT:
    % symbol    - is a ticker symbol i.e. 'AMD', 'BTC-USD'
    % startdate - the date from which the market data will be requested
    % enddate   - the market data will be requested till this date
    % interval  - the market data will be returned in this intervals
    % supported intervals are '1d', '5d', '1wk', '1mo', '3mo'
    %
    % Example: 
    %   data = getMarketDataViaYahooU('AMD', '1-Jan-2018', datetime('today'), '5d');
    % 
    % Author: Artem Lenskiy, PhD
    %
    % Version: 0.9 (requires urlread2())
    %
    % An alternative approach is given here
    % https://stackoverflow.com/questions/50813539/user-agent-cookie-workaround-to-web-scraping-in-matlab
    
     addpath('./V1_1_urlread2');
     
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
        'period1',  num2str(uint64(posixtime(datetime())), '%.10g'),...
        'period2',  num2str(uint64(posixtime(datetime())), '%.10g'),...
        'interval', interval,...
        'filter', 'history',...
        'frequency', interval,...
        'guccounter', 1);

    %% Extract the crumb value 
    % The ideas is taken from here:
    % http://blog.bradlucas.com/posts/2017-06-02-new-yahoo-finance-quote-download-url/
    % The while loop is used to make sure that generated crumb value does
    % not contains '\', since requestObj.send does not correctly send URLs
    % with slash
    crumb = "\";
    while(contains(crumb, '\'))
        [response, extras] = urlread2(uri.EncodedURI.char,'GET');
        ind = regexp(response, '"CrumbStore":{"crumb":"(.*?)"}');
        crumb = response(ind(1)+23:ind(1)+33);
    end
    
    %% Find the session cookie
    % The idea is taken from here:
    % https://stackoverflow.com/questions/40090191/sending-session-cookie-with-each-subsequent-http-request-in-matlab?rq=1
    if ~isempty(extras.firstHeaders)
        cookie = extras.firstHeaders.set_cookie;
    else
        disp('Check ticker symbol and that Yahoo provides data for it');
        data = [];
        return;
    end
    
    %% Send a request for data
    % It is important: 
    %       (1) to add session cookie that matches crumb values;
    %       (2) specify UserAgent
    options = weboptions('KeyName','Cookie','KeyValue', cookie,...
        'ContentType','text', 'UserAgent', 'Mozilla/5.0',...
        'ArrayFormat', 'csv', 'Timeout', 10);

    data = webread(['https://query1.finance.yahoo.com/v7/finance/download/', upper(symbol) ],...
        'period1',  num2str(uint64(startdate), '%.10g'),...
        'period2',  num2str(uint64(enddate), '%.10g'),...
        'interval', interval,...
        'events',   'history',...
        'crumb',    crumb,...
        options);
    data = formTable(string(data));
end

%% Convert data to the table format
function marketDataTable = formTable(data)
    records = data.splitlines;
    header = records(1).split(',');
    content = zeros(size(records, 1) - 2, size(header, 1) - 1);
    for k = 1:size(records, 1) - 2
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
	marketDataTable = table(dates', content(:,1), content(:,2),... 
            content(:,3), content(:,4), content(:,5),...
            content(:,6));
    for k = 1:size(header, 1)    
         marketDataTable.Properties.VariableNames{k} = char(header(k).replace(' ', ''));  
    end
end

