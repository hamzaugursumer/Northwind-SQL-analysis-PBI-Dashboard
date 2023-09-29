#  📑**Northwind Veri Seti - SQL Senaryoları ve PowerBI Görselleştirmeleri**

![img](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-2/blob/main/Northwind%20Data.png)

* 📌**Bitirme Projesinin bu ayağında ise bizlerden aynı şekilde dört adet Task istenmiştir ancak bu sefer yapmamız gereken sorgularımızı SQL de yazdıktan sonra PowerBI kullanarak etkileyici ve profesyonel bir dashboard hazırlamak.**
* 📌**Veri seti ile alakalı detaylı tüm bilgilere, ERD şemasına, veri setine ve diğer içeriklere [buradan](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-2) ulaşabilirsiniz.**
* 📌**Çalışmamın SQL sorgularının bulunduğu dosyaya [buradan](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/blob/main/Bitirme%20Projesi%20Sorgular%C4%B1.sql) ulaşabilirsiniz.**
* 📌**Çalışmamın PowerBI dashboardına [buradan](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/blob/main/Bitirme%20Projesi%20Dashboard.pbix) ulaşabilirsiniz.**
* 📌**Çalışmamın PowerBI dashboard PDF dosyasına [buradan](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/blob/main/Bitirme%20Projesi%20Dashboard.pdf) ulaşabilirsiniz.**

## 🚀 **İstenen Senaryolar**

* 🗝️**CASE 1 - Kategori Analizi ;**

Satış departmanı kategorilere göre bir gelir hesaplaması ve hangi kategori ve kategori içeriklerinden ne kadar gelir elde edildiğini görmek istiyor. Bu analizde bizden indirim ve kargo maliyetleri eklenmeden bir gelir, toplam indirim miktarı, toplam kargo maliyetlerini ve en son olarak bunlar 
çıkartılarak bir net gelir hesaplaması istemektedirler. Bunlar çıktımızda olması gereken KPI' lar olarak listelenmelidir.

````sql
with cte_category_sales as (
	select 
		c.category_id,
		category_name,
		description as category_description,
		round(sum(od.unit_price * od.quantity)::numeric,1) as total_sales_amount,
		round(sum(od.unit_price * od.quantity * od.discount)::numeric,1) as total_discount_amount,
		round(sum(o.freight)::numeric,1) as total_freight_cost
	from orders as o
		left join order_details as od
			ON od.order_id = o.order_id
		left join products as p 
			ON od.product_id = p.product_id
		left join categories as c
			ON c.category_id = p.category_id
	group by 1,2,3
	order by 1 
)
select 
	category_name,
	category_description,
	total_sales_amount,
	total_discount_amount,
	total_freight_cost,
	ROUND(
		total_sales_amount::numeric - (total_discount_amount + total_freight_cost)::numeric
		,1) as net_profit
from cte_category_sales
order by net_profit desc
````
----------------------------
|       | category_name      | category_description                                  | total_sales_amount | total_discount_amount | total_freight_cost | net_profit   |
| ----- | -------------------| ----------------------------------------------------| ------------------ | ----------------------| -------------------| ------------ |
| 1     | Beverages          | Soft drinks, coffees, teas, beers, and ales        | 286527.0           | 18658.8               | 39886.7            | 227981.5     |
| 2     | Dairy Products    | Cheeses                                              | 251330.5           | 16823.2               | 38164.0            | 196343.3     |
| 3     | Meat/Poultry       | Prepared meats                                      | 178188.8           | 15166.4               | 17769.2            | 145253.2     |
| 4     | Confections        | Desserts, candies, and sweet breads                 | 177099.1           | 9741.9                | 32819.9            | 134537.3     |
| 5     | Seafood            | Seaweed and fish                                    | 141623.1           | 10361.4               | 27723.0            | 103538.7     |
| 6     | Produce            | Dried fruit and bean curd                           | 105268.6           | 5284.0                | 13125.8            | 86858.8      |
| 7     | Condiments         | Sweet and savory sauces, relishes, spreads, and... | 113694.7           | 7647.7                | 20067.0            | 85980.0      |
| 8     | Grains/Cereals     | Breads, crackers, pasta, and cereal                 | 100726.8           | 4982.2                | 17750.5            | 77994.1      |
----------------------------
* 🗝️**CASE 2 - Çalışan Performans Analizi ;**

İnsan Kaynakları ve Büyüme ekibi şirket çalışanlarının satış performanslarını görmek istiyorlar. Bu performansı ise net gelir üzerinden kargo maliyeti ve indirimlerden sonra kalan net gelir ile ölçmektedirler. Şirket, çalışanlarının satış yaptıkları ürünlerin bir önceki satışına göre gerlirini
yüzde kaç arttırdığını görmek istiyorlar. Satılan ürünlerdeki fiyat değişimleri ve gelen sipariş miktarları göz ardı edilmelidir.

* Çalışanların ürün bazlı toplam satışları ;
````sql
with cte_sales as (
select 
	concat(e.first_name, ' ', e.last_name) as employee_name,
    o.order_date as date,
    p.product_name,
    od.quantity,
	o.order_date,
    round(sum((od.unit_price * od.quantity * (1 - od.discount)) - (o.freight / od.quantity))::numeric, 2) as total_sales
from employees as e
    left join orders as o 
		ON o.employee_id = e.employee_id
    left join order_details as od 
		ON o.order_id = od.order_id
    left join products as p 
		ON od.product_id = p.product_id
group by 1, 2, 3, 4, 5
order by 1
)
select 
	employee_name,
	order_date,
	sum(total_sales) as employee_sale_values
from cte_sales
group by 1,2
order by employee_name
````
----------------------------
|       | employee_name  | order_date | employee_sale_values |
| ----- | ---------------| -----------| ----------------------|
| 1     | Andrew Fuller  | 1996-07-25 | 1171.40              |
| 2     | Andrew Fuller  | 1996-08-09 | 1184.03              |
| 3     | Andrew Fuller  | 1996-08-14 | 611.70               |
| 4     | Andrew Fuller  | 1996-09-02 | 121.31               |
| 5     | Andrew Fuller  | 1996-09-09 | 606.53               |
| 6     | Andrew Fuller  | 1996-09-17 | 423.75               |
| 7     | Andrew Fuller  | 1996-09-23 | 1597.02              |
| 8     | Andrew Fuller  | 1996-09-24 | 182.24               |
| 9     | Andrew Fuller  | 1996-10-11 | 1802.28              |
| 10    | Andrew Fuller  | 1996-10-28 | 3351.65              |
* 768 satırlık çıktının ilk 10 satırı görüntülenmektedir.
----------------------------

* Çalışanların bir önceki ürün satışına göre yüzde değişimleri (negatif değerler dahil değildir) ; 
````sql
with sales as (
	select 
    	concat(e.first_name, ' ', e.last_name) as employee_name,
        o.order_date,
        p.product_name,
        od.unit_price,
        od.quantity,
        od.discount,
        round(o.freight::numeric / od.quantity::numeric, 2) as unit_freight_value,
        round(sum((od.unit_price * od.quantity * (1 - od.discount)) - (o.freight / od.quantity))::numeric, 2) as total_sales
    from employees as e
    	left join orders as o 
			ON o.employee_id = e.employee_id
    	left join order_details as od 
			ON o.order_id = od.order_id
    	left join products as p 
			ON od.product_id = p.product_id
    group by 1, 2, 3, 4, 5, 6, 7
),
lagged_sales as (
    select 
        s.employee_name,
        s.order_date,
        s.product_name,
        s.total_sales,
        lag(s.total_sales) over (partition by s.employee_name, s.product_name order by s.order_date) as previous_total_sales
    from sales as s
)
select 
    ls.employee_name,
    ls.order_date,
    ls.product_name,
    ls.total_sales,
    previous_total_sales,
    round((ls.total_sales - ls.previous_total_sales) / ls.total_sales, 2)*100 as sales_change_ratio
from lagged_sales as ls
where round((ls.total_sales - ls.previous_total_sales) / ls.total_sales, 2)*100 > 0;
````
----------------------------
|       | employee_name  | order_date | product_name                 | total_sales | previous_total_sales | sales_change_ratio |
| ----- | ---------------| -----------| ---------------------------- | ----------- | --------------------- | ------------------ |
| 1     | Andrew Fuller  | 1996-10-28 | Alice Mutton                 | 2074.58     | 934.16               | 55.00              |
| 2     | Andrew Fuller  | 1998-04-29 | Alice Mutton                 | 460.85      | 221.59               | 52.00              |
| 3     | Andrew Fuller  | 1997-09-04 | Camembert Pierrot            | 1008.24     | 693.30               | 31.00              |
| 4     | Andrew Fuller  | 1998-04-29 | Camembert Pierrot            | 1187.55     | 299.43               | 75.00              |
| 5     | Andrew Fuller  | 1997-07-03 | Carnarvon Tigers             | 1995.13     | 1403.74              | 30.00              |
| 6     | Andrew Fuller  | 1998-04-27 | Carnarvon Tigers             | 1748.48     | 438.56               | 75.00              |
| 7     | Andrew Fuller  | 1998-04-20 | Chai                         | 179.98      | 35.63                | 80.00              |
| 8     | Andrew Fuller  | 1998-05-05 | Chai                         | 608.60      | 179.98               | 70.00              |
| 9     | Andrew Fuller  | 1998-05-05 | Chang                        | 316.20      | 153.87               | 51.00              |
| 10    | Andrew Fuller  | 1998-01-22 | Chef Anton's Cajun Seasoning | 459.31      | 174.43               | 62.00              |
* 800 satırlık çıktının ilk 10 satırı görüntülenmektedir.
----------------------------

* Çalışan orderları ve satış yaptığı ürün sayısı ;
````sql
select 	
	concat(first_name, ' ', last_name) as employee_name,
	count(product_name) as product_count,
	count(distinct o.order_id) as order_count
from orders as o
left join employees as e
ON o.employee_id = e.employee_id
left join order_details as od
ON od.order_id = o.order_id
left join products as p
ON p.product_id = od.product_id
group by 1
````
----------------------------
|       | employee_name    | product_count | order_count |
| ----- | ----------------- | ------------- | ----------- |
| 1     | Andrew Fuller    | 241           | 96          |
| 2     | Anne Dodsworth   | 107           | 43          |
| 3     | Janet Leverling  | 321           | 127         |
| 4     | Laura Callahan   | 260           | 104         |
| 5     | Margaret Peacock | 420           | 156         |
| 6     | Michael Suyama   | 168           | 67          |
| 7     | Nancy Davolio    | 345           | 123         |
| 8     | Robert King      | 176           | 72          |
| 9     | Steven Buchanan  | 117           | 42          |
----------------------------

* 🗝️**CASE 3 - Ülkelerin Yıllara göre Top 1 Kategori Tercihleri ;**

Satış ekibi yıllara göre ülkelerin kategori tercihlerini merak etmektedir. Yıllar bazında ülkelerin kategori popüleritesini ölçebilmek adına toplam order sayıları belirlenmiştir. En fazla order sayısına sahip "top 1" kategoriler belirlenmelidir.

````sql
with cte_monthly_orders as (
	select 
		date_trunc('Year', o.order_date)::date as order_month,
		ship_country,
		category_name,
		count(o.order_id) total_order
	from orders as o
		left join order_details as od
			ON od.order_id = o.order_id
		left join products as p
			ON p.product_id = od.product_id
		left join categories as c
			ON c.category_id = p.category_id
	group by 1,2,3
	order by 2
),
ranked_products as (
	select 
		order_month,
		ship_country,
		category_name,
		total_order,
		rank() over (partition by order_month, ship_country order by total_order desc) as top_category
	from cte_monthly_orders
)
select 
	ship_country,
	order_month,
	category_name,
	total_order,
	top_category
from ranked_products
where top_category = 1
order by ship_country
````
----------------------------
|       | ship_country | order_month | category_name    | total_order | top_category |
| ----- | ------------ | ----------- | ---------------- | ----------- | ------------ |
| 1     | Argentina    | 1998-01-01  | Beverages        | 6           | 1            |
| 2     | Argentina    | 1997-01-01  | Confections      | 4           | 1            |
| 3     | Austria      | 1997-01-01  | Dairy Products   | 13          | 1            |
| 4     | Austria      | 1996-01-01  | Dairy Products   | 6           | 1            |
| 5     | Austria      | 1998-01-01  | Beverages        | 9           | 1            |
| 6     | Belgium      | 1998-01-01  | Beverages        | 7           | 1            |
| 7     | Belgium      | 1996-01-01  | Dairy Products   | 2           | 1            |
| 8     | Belgium      | 1997-01-01  | Confections      | 5           | 1            |
| 9     | Brazil       | 1998-01-01  | Beverages        | 14          | 1            |
| 10    | Brazil       | 1996-01-01  | Beverages        | 9           | 1            |
* 80 satırlık çıktının ilk 10 satırı görüntülenmektedir.
----------------------------

* Kategori ve ülke bazında order sayıları ; 
````sql
select 
	ship_country,
	category_name,
	count(distinct o.order_id) total_order
from orders as o
	left join order_details as od
		ON od.order_id = o.order_id
	left join products as p
		ON p.product_id = od.product_id
	left join categories as c
		ON c.category_id = p.category_id
group by 1,2
order by 2
````
----------------------------
|       | ship_country | category_name | total_order |
| ----- | ------------ | ------------- | ----------- |
| 1     | Argentina    | Beverages     | 6           |
| 2     | Austria      | Beverages     | 20          |
| 3     | Belgium      | Beverages     | 8           |
| 4     | Brazil       | Beverages     | 37          |
| 5     | Canada       | Beverages     | 10          |
| 6     | Denmark      | Beverages     | 7           |
| 7     | Finland      | Beverages     | 9           |
| 8     | France       | Beverages     | 32          |
| 9     | Germany      | Beverages     | 51          |
| 10    | Ireland      | Beverages     | 9           |
* 165 satırlık çıktının ilk 10 satırı görüntülenmektedir.
----------------------------

* Ülke bazında satılan ürün sayısı ;
````sql
select 
	ship_country,
	count(p.product_id) as product_count
from orders as o
	left join order_details as od
		ON od.order_id = o.order_id
	left join products as p
		ON p.product_id = od.product_id
	left join categories as c
		ON c.category_id = p.category_id
group by 1
order by 2
````
----------------------------
|       | ship_country  | product_count |
| ----- | ------------- | ------------- |
| 1     | Norway        | 16            |
| 2     | Poland        | 16            |
| 3     | Portugal      | 30            |
| 4     | Argentina     | 34            |
| 5     | Denmark       | 46            |
| 6     | Switzerland   | 52            |
| 7     | Italy         | 53            |
| 8     | Finland       | 54            |
| 9     | Spain         | 54            |
| 10    | Ireland       | 55            |
* 21 satırlık çıktının ilk 10 satırı görüntülenmektedir.
----------------------------

* 🗝️**CASE 4 - Aylık Büyüme Oranları ;** 

Finans ekibi şirketin büyüme oranlarını belirlemek amacıyla yıl ve aylar bazında net gelir hesaplama talebinde bulunuyor. Bu hesaplama sonucunda net gelirin yanı sıra bir önceki aya göre büyüme oranlarının da görünmesini istiyorlar.

````sql
with cte_monthly_net_profit as (
	select 
		to_char(o.order_date , 'YYYY-MM') as year_month,
		round(sum(od.unit_price * od.quantity)::numeric,1) as total_sales_amount,
		round(sum(od.unit_price * od.quantity * od.discount)::numeric,1) as total_discount_amount,
		round(sum(o.freight)::numeric,1) as total_freight_cost
	from orders as o
		left join order_details as od
			ON od.order_id = o.order_id
	group by 1
	order by 1
),
profit as (
	select 
		year_month,
		total_sales_amount - (total_discount_amount + total_freight_cost) as net_profit_
	from cte_monthly_net_profit
),
monthly_growth as (
	select 
		year_month,
		net_profit_,
		lag(net_profit_) over (order by year_month) as prev_monthly_revenue
	from profit
)
select 
	year_month,
	net_profit_,
	prev_monthly_revenue,
	ROUND(((net_profit_ - prev_monthly_revenue) / prev_monthly_revenue) * 100,2) as growth_percentage
from monthly_growth
order by 1
````
----------------------------
|       | year_month | net_profit_ | prev_monthly_revenue | growth_percentage |
| ----- | ---------- | ----------- | -------------------- | ----------------- |
| 1     | 1996-07    | 23861.0     |                      |                   |
| 2     | 1996-08    | 21136.9     | 23861.0              | -11.42            |
| 3     | 1996-09    | 23074.0     | 21136.9              | 9.16              |
| 4     | 1996-10    | 32092.4     | 23074.0              | 39.08             |
| 5     | 1996-11    | 39614.6     | 32092.4              | 23.44             |
| 6     | 1996-12    | 36233.4     | 39614.6              | -8.54             |
| 7     | 1997-01    | 54235.6     | 36233.4              | 49.68             |
| 8     | 1997-02    | 33384.2     | 54235.6              | -38.45            |
| 9     | 1997-03    | 31930.0     | 33384.2              | -4.36             |
| 10    | 1997-04    | 43055.6     | 31930.0              | 34.84             |
| 11    | 1997-05    | 41509.8     | 43055.6              | -3.59             |
| 12    | 1997-06    | 30848.8     | 41509.8              | -25.68            |
| 13    | 1997-07    | 42399.4     | 30848.8              | 37.44             |
| 14    | 1997-08    | 37601.1     | 42399.4              | -11.32            |
| 15    | 1997-09    | 44694.4     | 37601.1              | 18.86             |
| 16    | 1997-10    | 52701.6     | 44694.4              | 17.92             |
| 17    | 1997-11    | 37493.3     | 52701.6              | -28.86            |
| 18    | 1997-12    | 60439.2     | 37493.3              | 61.20             |
| 19    | 1998-01    | 75194.5     | 60439.2              | 24.41             |
| 20    | 1998-02    | 88874.1     | 75194.5              | 18.19             |
| 21    | 1998-03    | 88741.6     | 88874.1              | -0.15             |
| 22    | 1998-04    | 103612.2    | 88741.6              | 16.76             |
| 23    | 1998-05    | 15758.9     | 103612.2             | -84.79            |
----------------------------

## 🚀 **Elde edilen çıktıların Dashboardları**
* 🗝️**CASE 1 - Kategori Analizi ;**

![image](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/assets/127680099/e22bb2bc-29dc-4b9a-bca4-c4a4ca276cad)


* 🗝️**CASE 2 - Çalışan Performans Analizi ;**

![image](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/assets/127680099/18d585f3-45cf-4a2f-a417-080a1105bb52)


* 🗝️**CASE 3 - Ülkelerin Yıllara göre Top 1 Kategori Tercihleri ;**

![image](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/assets/127680099/253b4880-ffe0-4b90-89be-22073eff224c)


* 🗝️**CASE 4 - Aylık Büyüme Oranları ;**

![image](https://github.com/hamzaugursumer/CapstoneProjectKodlasam-3/assets/127680099/0862d64a-5a52-4d38-b1d1-ffbd99f39241)
