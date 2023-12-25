-- first I got familiar with the data by selecting all colums from all relevant tables

select * from mintclassics.products;
select * from mintclassics.productslines;
select * from mintclassics.orderdetails;
select * from mintclassics.orders;

-- South warehouse has the largest capacity
select * 
	from mintclassics.warehouses 
		order by warehousePctCap desc;



-- I have decided to stay on sub-category (productLine) level during the analysis and not to break down 
-- to specific models. I wanted to see how the certain sub-categories are distributed 
-- and stocked in warehouses

select distinct 
	productLine, 
	warehouseCode 
		from mintclassics.products
			order by warehouseCode;


-- In order to be able to group sub-categories a gave them a specific number. 
-- This helped me to see the the total value of orders for each sub-categories
-- I have created a table to store this data and be able to sum and count later

drop table mintclassics.prod3;
create table mintclassics.prod3 (productLine varchar(255),ProductLineNr2 int);
insert into mintclassics.prod3 (select distinct productLine, 
									(case when productLine = 'Motorcycles' then 1
										when productLine = 'Classic Cars' then 2
											when productLine = 'Vintage Cars' then 3
												when productLine = 'Trucks and Buses' then 4
													when productLine = 'Planes' then 5
														when productLine = 'Ships' then 6
															when productLine = 'Trains' then 7
																else 0 end) as ProductLineNr2 
																		from mintclassics.products)
                                                  ;
-- Sense check of the new Table
select distinct * from mintclassics.prod3;

-- As a next step, I was digging deeper into the orders to find out which sub-categories 
-- are bringing the most value to the company. Therefore I have created a Table to 
-- connect order details to product details.

drop table mintclassics.orderdetails2;
create table mintclassics.orderdetails2 as
select distinct 
	orderdetails.orderNumber, 
	orderdetails.productCode, 
	orderdetails.quantityOrdered, 
	orderdetails.priceEach, 
	orderdetails.orderLineNumber, 
	products.productName, 
	products.productLine,
	prod3.ProductLineNr2, 
	products.warehouseCode
		from mintclassics.orderdetails
			left join mintclassics.products 
				on orderdetails.productCode=products.productCode
			left join mintclassics.prod3 
				on products.productLine = prod3.productLine
		order by orderNumber;
        
-- I sum up the total sales of each sub-category and ordered by on value in descending order. 
-- It turned out, that classic and vintage cars are adding the most value, whilst Ship 
-- and Train models are the least ordered categories.

select 
	sum(priceEach) as totalsales, 
	ProductLineNr2
		from mintclassics.orderdetails2 
			group by ProductLineNr2 
			order by sum(priceEach) desc ;

-- Now we know what are the least consumed sub-categories and where are these sub-categories are stored.
-- In the followings I aimed to investigate deeper the orders, in order to see warehouse efficiency
-- Ontimeshipping is being defined with a simple excercise. If the shipping date = the required date
-- , then I considered as on-time shipping

select count(orderNumber) from mintclassics.orders
where requiredDate=shippedDate;

-- Selecting on-time delivery cases and connected to warehouses to see efficiency
drop table mintclassics.Ontimeshipping;
create table mintclassics.Ontimeshipping as
select distinct 
	orders.orderNumber, 
	orders.requiredDate, 
	orders.shippedDate, 
	orderdetails2.productLine, 
	orderdetails2.ProductLineNr2, 
	orderdetails2.warehouseCode
		from mintclassics.orders
			left join mintclassics.orderdetails2 
				on orders.orderNumber=orderdetails2.orderNumber
					where orders.requiredDate=orders.shippedDate
						order by  orderdetails2.warehouseCode;

-- counting on-time deliveries for certain warehouses
drop table mintclassics.OntimeShCnt;
create table mintclassics.OntimeShCnt as
select 
	warehouseCode, 
	count(warehouseCode) as ontimeshcount 
		from mintclassics.Ontimeshipping 
        group by warehouseCode;


-- With the same structure as above, selecting and connecting all deliveries
drop table mintclassics.Allshipping;
create table mintclassics.Allshipping as
select distinct 
	orders.orderNumber, 
	orders.requiredDate, 
    orders.shippedDate,
    orderdetails2.productLine, 
    orderdetails2.ProductLineNr2, 
    orderdetails2.warehouseCode
		from mintclassics.orders
			left join mintclassics.orderdetails2 
				on orders.orderNumber=orderdetails2.orderNumber
					order by  orderdetails2.warehouseCode;

drop table mintclassics.AllShCnt;
create table mintclassics.AllShCnt as
select 
	warehouseCode, 
	count(warehouseCode) as allshcount 
		from mintclassics.Allshipping 
        group by warehouseCode;

-- And finally: Calculating efficiency for certain warehouses
select AllShCnt. warehouseCode, allshcount, ontimeshcount, (ontimeshcount/allshcount) as efficiency
	from mintclassics.AllShCnt
		left join mintclassics.OntimeShCnt 
			on AllShCnt.warehouseCode = OntimeShCnt.warehouseCode;

-------------------------------------------------------------------------------------------

-- select * from mintclassics.customers;

-- drop table mintclassics.Prod2;
-- create table mintclassics.Prod2 as
-- (select productCode, 
	-- (case when productLine = 'Motorcycles' then 1
							-- when productLine = 'Classic Cars' then 2
								-- when productLine = 'Vintage Cars' then 3
									-- when productLine = 'Trucks and Buses' then 4
										-- when productLine = 'Planes' then 5
											-- when productLine = 'Ships' then 6
												-- when productLine = 'Trains' then 7
													-- else 0 end) as ProductLineNr, 
-- productLine, 
-- productName, 
-- buyPrice 
-- from mintclassics.products);


-- select distinct warehouseCode, count(productCode), sum(buyPrice) from mintclassics.products
-- group by warehouseCode;

-- select distinct 
	-- sum(products.buyprice) as sumprice, 
	-- ProductLineNr2, 
	-- count(prod3.productLine) as dbProd 
		-- from mintclassics.prod3
			-- left join mintclassics.products 
				-- on products.productLine= prod3.productLine
		-- group by prod3.ProductLineNr2
		-- order by sumprice desc;

-- select distinct 
	-- warehouses.warehouseCode, 
	-- warehouses.warehouseName, 
	-- products.productLine, 
	-- prod3.ProductLineNr2
		-- from mintclassics.warehouses
			-- left join mintclassics.products 
				-- on warehouses.warehouseCode=products.warehouseCode
		-- left join mintclassics.prod3 on products.productLine = prod3.productLine
		-- ;
        
-- select distinct orderdetails.orderNumber, orderdetails.productCode, orderdetails.quantityOrdered, 
-- orderdetails.priceEach, orderdetails.orderLineNumber, products.productName, products.productLine
-- from mintclassics.orderdetails
-- left join mintclassics.products on orderdetails.productCode=products.productCode
-- order by orderNumber;