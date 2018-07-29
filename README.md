# Yahoo finance data download demonstration

## Example 1
```ruby
disp('Request historical YTD Bitcoin price and plot Close, High and Low');
initDate = '1-Jan-2018';
symbol = 'BTC-USD';
btcusd = getMarketDataViaYahoo(symbol, initDate);
btcusdts = timeseries([btcusd.Close, btcusd.High, btcusd.Low], datestr(btcusd(:,1).Date));
btcusdts.DataInfo.Units = 'USD';
btcusdts.Name = symbol;
plot(btcusdts);
legend({'Close', 'High', 'Low'});
```

![btcprice](figures/btcprice.png)

## Example 2
```ruby
disp('Request data for a number of sybmols and calculate covariance matrix');

clear marketData;
initDate = datetime(addtodate(datenum(today),-1,'year'),'ConvertFrom','datenum');
symbols = {'^GSPC', 'DAX',  '^N225', 'GLD', 'QQQ', '^IXIC', 'FNCL', 'BTC-USD'};

for k = 1:length(symbols)
    data = getMarketDataViaYahoo(symbols{k}, initDate);
    ts(k) = timeseries(data.Close, datestr(data(:,1).Date));
    tsout = resample(ts(k),ts(1).Time);
    marketData(:,k) = tsout.Data;
end

marketData(isnan(marketData)) = 0; %# In case resample() introduced NaNs
normalizedPrice = (marketData - mean(marketData))./std(marketData);
normalizedPrice = normalizedPrice - normalizedPrice(1,:);
tscomb = timeseries(normalizedPrice);
tscomb.TimeInfo = ts(1).TimeInfo;
tscomb.Name = 'normalized';
figure, plot(tscomb);
legend(symbols, 'interpreter', 'none', 'Location', 'best');

covMat = corrcoef(marketData);
covMat(eye(8) == 1) = 0;

figure, heatmap(covMat,'Colormap', parula(3), 'ColorbarVisible', 'on');
ax = gca;
ax.XData = symbols;
ax.YData = symbols;
```
![btcprice](figures/comb_norm_prices.png)
![btcprice](figures/covmat.png)
