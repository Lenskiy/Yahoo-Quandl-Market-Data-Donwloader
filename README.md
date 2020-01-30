# Yahoo finance and Quandl data downloader
[![View Yahoo Finance and Quandl data downloader on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://au.mathworks.com/matlabcentral/fileexchange/68361-yahoo-finance-and-quandl-data-downloader)

## Example 1: Download data from Yahoo
```ruby
initDate = '1-Jan-2014';
symbol = 'AAPL';
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";
```

<img src="https://github.com/Lenskiy/market-data-functions/blob/master/Figures/example_1and2.png" width="80%">

## Example 2: Download data from Quandl
```ruby
dataset = 'WIKI/AAPL';
aaplusd_quanl_raw = getMarketDataViaQuandl(dataset, initDate);
aaplusd_quanl= timeseries([aaplusd_quanl_raw.Close, aaplusd_quanl_raw.High, aaplusd_quanl_raw.Low], datestr(aaplusd_quanl_raw(:,1).Date));
aaplusd_quanl.DataInfo.Units = 'USD';
aaplusd_quanl.Name = dataset;
aaplusd_quanl.TimeInfo.Format = "dd-mm-yyyy";


figure, % note the Quandl returns inaccurate date
subplot(2,1,1), plot(aaplusd_yahoo);
legend({'Close', 'High', 'Low'},'Location', 'northwest');
subplot(2,1,2), plot(aaplusd_quanl);
legend({'Close', 'High', 'Low'},'Location', 'northeast');
```
## Example 3: Download data OPEC Basket Price from Quandl
```ruby
dataset = 'OPEC/ORB';
opec_orb_raw = getMarketDataViaQuandl(dataset, initDate, date(), 'weekly');
opec_orb_ts = timeseries(opec_orb_raw.Value, datestr(opec_orb_raw.Date));
opec_orb_ts.DataInfo.Units = 'USD';
opec_orb_ts.Name = dataset;
opec_orb_ts.TimeInfo.Format = "dd-mm-yyyy";
figure, plot(opec_orb_ts);
```

## Example 4: Download data from Yahoo and estimate covariance matrix
```ruby
clear marketData;
initDate = datetime(addtodate(datenum(today),-1,'year'),'ConvertFrom','datenum');
symbols = {'^GSPC', 'DAX',  '^N225', 'GLD', 'QQQ', '^IXIC', 'FNCL', 'BTC-USD'};

for k = 1:length(symbols)
    data = getMarketDataViaYahoo(symbols{k}, initDate);
    ts(k) = timeseries(data.Close, datestr(data(:,1).Date));
    tsout = resample(ts(k),ts(1).Time);
    marketData(:,k) = tsout.Data;
end

marketData(isnan(marketData)) = 0; % In case resample() introduced NaNs
normalizedPrice = (marketData - mean(marketData))./std(marketData);
normalizedPrice = normalizedPrice - normalizedPrice(1,:);
tscomb = timeseries(normalizedPrice);
tscomb.TimeInfo = ts(1).TimeInfo;
tscomb.Name = 'normalized';
tscomb.TimeInfo.Format = "dd-mm-yyyy";
figure, plot(tscomb);
legend(symbols, 'interpreter', 'none', 'Location', 'best');

covMat = corrcoef(marketData);
covMat(eye(8) == 1) = 0;

figure, heatmap(covMat,'Colormap', parula(3), 'ColorbarVisible', 'on');
ax = gca;
ax.XData = symbols;
ax.YData = symbols;
```
<img src="https://github.com/Lenskiy/market-data-functions/blob/master/Figures/comb_norm_prices.png" width="80%">
<img src="https://github.com/Lenskiy/market-data-functions/blob/master/Figures/covmat.png" width="80%">
