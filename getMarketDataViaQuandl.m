function data = getMarketDataViaQuandl(set_name, startdate, enddate, collapse, key)
    % Downloads market data from Quandl for a specified symbol and 
    % time range.
    % 
    % INPUT:
    % set_name  - is a dataset name i.e. 'WIKI/AAPL'
    % startdate - the market data will be requested from this data
    % enddate   - the market data will be requested till this date
    % collapse  - the market data will be returned in this intervals
    % supported intervals are 'daily', 'weekly', 'monthly', 'quarterly', 'annual'
    % key       - user's api key
    %
    % OUTPUT:
    % data - is a retrieved  dataset returned as a table
    %
    % Example: 
    %   data = getMarketDataViaQuandl('LBMA/GOLD', initDate, date(), 'monthly');
    % 
    % Author: Artem Lenskiy, PhD
    % Version: 1.13
  
    if(nargin() == 1)
        startdate = datetime('1-Jan-2018');
        enddate = date(); % now
        collapse = 'daily';
        key = '';
    elseif (nargin() == 2)
        startdate = startdate;
        enddate = date(); % now
        collapse = 'daily';
        key = '';
    elseif (nargin() == 3)      
        collapse = 'daily';
        key = '';
    elseif(nargin() == 4)
        key = '';
    elseif(nargin() == 5)
        
    else
        error('At least one parameter is required. Specify dataset.');
        data = [];
        return;
    end
    
    %% Construct an URL 
    uri = matlab.net.URI(['https://www.quandl.com/api/v3/datasets/', upper(set_name), '.csv'],...
        'start_date',  startdate,...
        'end_date',  enddate,...
        'collapse', collapse,...
        'order', 'asc',...
        'api_key', key);
    %% Send a request
    options = matlab.net.http.HTTPOptions('ConnectTimeout', 20, 'DecodeResponse', 1, 'Authenticate', 0, 'ConvertResponse', 0);
    requestObj = matlab.net.http.RequestMessage();
    [response, ~, ~]  = requestObj.send(uri, options);
    if(~strcmp(response.StatusCode, 'OK'))
        disp(response.Body.Data);
        data = [];
    else
        data = formTableQuandl(response.Body.Data);
    end
end

%% Convert data to the table format
function procData = formTableQuandl(data)
    records = data.splitlines;
    header = records(1).split(',');
    content = zeros(size(records, 1) - 2, size(header, 1) - 1);
    for k = 1:size(records, 1) - 2 % -2 because last line is always empty
        items = records(k + 1).split(',');
        dates(k) = datetime(items(1));
        for l = 2:size(header, 1)
            content(k, l - 1) = str2double(items(l));
        end
    end
    
    procData = [table(dates'), array2table(content)];
  
    for k = 1:size(header, 1)    
         procData.Properties.VariableNames{k} = char(header(k).replace(' ', ''));  
    end
end
