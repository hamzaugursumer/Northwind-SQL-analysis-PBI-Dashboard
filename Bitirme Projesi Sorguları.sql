-- Tablolar ve kısa açıklamaları ; 

select * from customers -- müşteri bilgilerini firmaları ve firma temsilci bilgilerini içerir.
select * from territories -- çalışanın çalıştığı bölge bilgisi ve o bölgenin hangi region a karşılık geldiği bilgsisini içerir.
select * from employee_territories -- çalışanın, çalışma bölge bilgisini içerir. Çalışanlar birden fazla bölgede çalışmaktadır.
select * from employees -- çalışan kişi bilgilerini içerir.
select * from region -- bölge ve bölge açıklamalarını içerir.


select * from order_details -- Verilen siparişin ürün, fiyat, miktar ve indirim bilgisini içerir.
select * from orders -- müşteri tarafından verilen siparişin sipariş tarih bilgileri, taşıma maliyeti, ve teslim adres bilgilierini vs. içerir.
select * from products -- ürün bilgisini, hangi kategoride ve tedarikçide olduğu, birim fiyatı vs. ve satışının devam edip etmediği bilgisi.
select * from shippers -- taşıma şirketi bilgisini içerir.
select * from suppliers -- tedarikçi bilgilerini içermektedir.
select * from categories -- ürün kategorilerini ve acıklamalarını içerir.

--***************************************************************************************************************************************************

-- CASE 1 - Bölge Analizi ; (python)

-- Pazarlama ekibi bölgeler baz alınarak sipariş miktarları ve ortalama indirim dahil geliri
-- hesaplamak istemektedirler.
-- Bölgeleri, toplam sipariş sayısı ve indirim dahil ortalama tutarları görmek istiyorlar.

with cte_sales as (
	select 
		r.region_id as region_id,
		r.region_description as region_name,
		count(distinct o.order_id) as total_orders,
		sum(od.unit_price * od.quantity * (1 - od.discount)) as total_sales_amount_including_discount
	from orders as o
		left join order_details as od 
			ON od.order_id = o.order_id
		left join employees as e
			ON e.employee_id = o.employee_id
		left join employee_territories as et
			ON et.employee_id = e.employee_id
		left join territories as t 
			ON t.territory_id = et.territory_id
		left join region as r
			ON r.region_id = t.region_id
	group by 1,2
)
select 
	region_name,
	total_orders,
	ROUND(
		total_sales_amount_including_discount::numeric / total_orders
		,1) as avg_unit_sales_amount_including_discount
from cte_sales 

--***************************************************************************************************************************************************


-- CASE 2 - Kategori Analizi ; (powerbi)

-- Satış departmanı kategorilere göre bir gelir hesaplaması ve  
-- hangi kategori ve kategori içeriklerinden ne kadar gelir elde edildiğini görmek istiyor. 
-- Bu analizde bizden indirim ve kargo maliyetleri eklenmeden bir gelir,
-- toplam indirim miktarı, toplam kargo maliyetlerini ve en son olarak bunlar
-- çıkartılarak bir net gelir hesaplaması istemektedirler. Bunlar çıktımızda olması 
-- gereken KPI' lar olarak listelenmelidir.

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

--***************************************************************************************************************************************************


-- CASE 3 - Çalışan Performans Analizi ; (powerbi)

-- İnsan Kaynakları ve Büyüme ekibi şirket çalışanlarının satış performanslarını
-- görmek istiyorlar. Bu performansı ise net gelir üzerinden kargo maliyeti ve indirimlerden
-- sonra kalan net gelir ile ölçmektedirler. Şirket, çalışanlarının satış yaptıkları ürünlerin bir önceki satışına göre gerlirini
-- yüzde kaç arttırdığını görmek istiyorlar. Satılan ürünlerdeki fiyat değişimleri ve gelen sipariş miktarları göz ardı edilmelidir.


-- çalışanların ürün bazlı toplam satışları ;
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


-- çalışanların bir önceki ürün satısına göre yüzde değişimleri (negatif değerler dahil değildir.) ; 
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


-- çalışan order ve satış yaptığı ürün sayısı ;
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

--***************************************************************************************************************************************************

-- CASE 4 - Taşıma şirketi Performans Analizi ; (python)

-- Şirket çalıştığı kargo firmalarının ne kadar teslimat yaptığını,
-- ortalama teslimat sürelerini ve müşteri için istenilen ortalama teslimat sürelerini
-- istemektedir. Ek olarak ortalama kargo maliyetleri de istenmektedir.

select 
	company_name,
	count(o.order_id) as total_order,
	round(avg((shipped_date - order_date)::numeric),0) as avg_shipping_day,
	round(avg((required_date - order_date)::numeric),0) as average_required_time,
	round(avg(freight)::numeric,0) as avg_freight
from orders as o
left join shippers as s
ON o.ship_via = s.shipper_id
group by 1;

--***************************************************************************************************************************************************

-- CASE 5 - Ülkelerin Yıllara göre Top 1 Kategori Tercihleri ; (powerbi)

-- Satış ekibi yıllara göre ülkelerin kategori tercihlerini merak etmektedir.
-- Yıllar bazında ülkelerin kategori popüleritesini ölçebilmek adına toplam order sayıları 
-- belirlenmiştir. En fazla order sayısına sahip "top 1" kategoriler belirlenmelidir.

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
--where top_category = 1
order by ship_country



-- kategori ve ülke bazında order sayıları ; 
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
;

-- ülke bazında satılan ürün sayısı ;
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
;

--***************************************************************************************************************************************************

-- CASE 6 - Tedarikçi Analizi (python)

-- Satın Alma ekibi, tedarik edilen ürünlerle ilgili ayrıntılı bilgilere ulaşmak ve gerekli aksiyonları almak istiyor. 
-- Bu analizde, tedarikçilerin listesi, tedarikçilerin bulunduğu şehirler, her bir tedarikçinin ne kadar benzersiz 
-- ürün temin ettiği ve bu ürünlerin hangi kategorilere ait olduğunu görmek istiyorlar. Ayrıca, tedarikçiler bazında ürün sayısı 
-- ve toplam ürün tedarik sayısına göre yüzdelik dilimlere ayrılan bilgilere de ihtiyaçları var.


with cte_supp as (
	select 
		sup.company_name,
		sup.city,
		count(distinct p.product_id) as number_of_distinct_products,
		string_agg(distinct c.category_name, ', ') as product_categories,
		count(p.product_id) as suppliers_supply_count
	from suppliers as sup
		left join products as p
			ON p.supplier_id = sup.supplier_id
		left join categories as c
			ON c.category_id = p.category_id
		left join order_details as od
			ON od.product_id = p.product_id
		left join orders as o
			ON o.order_id = od.order_id
	group by 1,2
),
total_orders as (
	select
		sum(suppliers_supply_count) as total_order 
	from cte_supp
)
select 
	cte.company_name,
	cte.city,
	cte.number_of_distinct_products,
	cte.product_categories,
	cte.suppliers_supply_count,
	round((cte.suppliers_supply_count / total_orders.total_order)*100,2) as suppliers_percentage
from cte_supp as cte, total_orders 
order by suppliers_percentage desc

--***************************************************************************************************************************************************

-- CASE 7 - Ürün ve Stok Analizi ; (python)

-- Ürün ekibi, envanter analizi yapmak ve ürün bazında ihtiyaçları belirlemek istiyor. 
-- Bu kapsamda siparişlerde tekrar edilen ürünleri, yeterli stoku olan ürünleri, 
-- satışı devam eden ve sona eren ürünlerin adetlerini görmek istiyorlar. 
-- Ayrıca en çok tekrar sipariş edilen ve en fazla stoku bulunan ilk 5 ürünün listesini de talep ediyorlar.


-- yeniden sipariş edilen ürün, yeterli stok olan ürün ve ürünün discontinued durumlarına göre adetleri ; 
with product_inventory as (
select
	o.order_id,
    p.product_name,
    p.unit_in_stock,
    p.unit_on_order,
    p.reorder_level,
    p.discontinued,
    	case
        	when p.unit_in_stock <= p.reorder_level then 'Reorder Required'
     	    when p.unit_in_stock > p.reorder_level then 'Sufficient Stock'
    			end as stock_status,
    	case
     	    when p.discontinued = 1 then 'Discontinued'
      		when p.discontinued = 0 then 'Active'
    			end as product_status
from orders as o
	left join order_details as od 
		ON o.order_id = od.order_id
    left join products as p 
		ON p.product_id = od.product_id
)
select
	stock_status as stock_and_discountinued_status,
    count(*) as count_
from product_inventory
group by stock_status

union all

select
	product_status,
    count(*) as product_status_count
from product_inventory
group by product_status;




-- en çok yeniden sipariş edilen top 5 ürün 
with product_inventory as (
	select
		p.product_name,
   		p.unit_in_stock,
    	p.unit_on_order,
   		p.reorder_level,
    	p.discontinued,
			case
      			when p.unit_in_stock <= p.reorder_level then 'Reorder Required'
      			when p.unit_in_stock > p.reorder_level then 'Sufficient Stock'
    		end as stock_status
	from orders as o
  		left join order_details as od 
			ON o.order_id = od.order_id
		left join products as p 
			ON p.product_id = od.product_id
), 
stock_counts as (
  	select
    	pi.product_name,
    	pi.stock_status,
    	count(*) as stock_status_count
  	from product_inventory as pi
  	group by 1,2
)
select
	product_name,
  	stock_status,
  	stock_status_count
from stock_counts
where stock_status = 'Reorder Required'
order by stock_status_count desc
limit 5;




-- en çok stokta bulunan top 5 ürün 
with product_inventory as (
	select
		p.product_name,
   		p.unit_in_stock,
    	p.unit_on_order,
   		p.reorder_level,
    	p.discontinued,
			case
      			when p.unit_in_stock <= p.reorder_level then 'Reorder Required'
      			when p.unit_in_stock > p.reorder_level then 'Sufficient Stock'
    		end as stock_status
	from orders as o
  		left join order_details as od 
			ON o.order_id = od.order_id
		left join products as p 
			ON p.product_id = od.product_id
), 
stock_counts as (
  	select
    	pi.product_name,
    	pi.stock_status,
    	count(*) as stock_status_count
  	from product_inventory as pi
  	group by 1,2
)
select
	product_name,
  	stock_status,
  	stock_status_count
from stock_counts
where stock_status = 'Sufficient Stock'
order by stock_status_count desc
limit 5;


--***************************************************************************************************************************************************

-- CASE 8 - Aylık Büyüme Oranları ; (powerbi)

-- Finans ekibi şirketin büyüme oranlarını belirlemek amacıyla yıl ve aylar bazında net gelir hesaplama talebinde bulunuyor. 
-- Bu hesaplama sonucunda net gelirin yanı sıra bir önceki aya göre büyüme oranlarının da görünmesini istiyorlar.


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




