/*

Cleaning data in sql queries

*/

select * 
from nashville_housing nh 

-- Standardize date format

select saledate, cast(saledate as date)
from nashville_housing nh;

alter table nashville_housing 
add saledateconverted date

update nashville_housing 
set saledateconverted = cast(saledate as date);

-- Populate property address data

select *
from nashville_housing nh
--where propertyaddress like ''
order by parcelid 

select nh.parcelid, nh.propertyaddress, nh2.parcelid, nh2.propertyaddress, 
coalesce(nullif(nh.propertyaddress, ''), nh2.propertyaddress)
from nashville_housing nh 
join nashville_housing nh2 
	on nh.parcelid = nh2.parcelid 
	and nh."UniqueID" <> nh2."UniqueID" 
where nh.propertyaddress like '';

update nashville_housing
set propertyaddress = coalesce(nullif(nh.propertyaddress, ''), nh2.propertyaddress)
from nashville_housing nh 
join nashville_housing nh2 
	on nh.parcelid = nh2.parcelid 
	and nh."UniqueID" <> nh2."UniqueID" 
where nh.propertyaddress like '';


-- Breaking out property and owner address into individual columns (Address, City, State)

select propertyaddress,
substring(propertyaddress, 0, position(',' in propertyaddress)) as propertysplitaddress,
substring(propertyaddress, position(',' in propertyaddress) + 2) as propertysplitcity
from nashville_housing nh 


alter table nashville_housing 
add propertysplitaddress varchar(50);

alter table nashville_housing 
add propertysplitcity varchar(50);

update nashville_housing 
set propertysplitaddress = substring(propertyaddress, 0, position(',' in propertyaddress))

update nashville_housing 
set propertysplitcity = substring(propertyaddress, position(',' in propertyaddress) + 2)

select propertysplitaddress, propertysplitcity
from nashville_housing nh 

alter table nashville_housing 
add ownersplitaddress varchar(50);

alter table nashville_housing 
add ownersplitcity varchar(50);

alter table nashville_housing 
add ownersplitstate varchar(50);

select split_part(owneraddress, ',', 1),
split_part(owneraddress, ',', 2),
split_part(owneraddress, ',', 3)
from nashville_housing nh 


update nashville_housing 
set ownersplitaddress = split_part(owneraddress, ',', 1)

update nashville_housing 
set ownersplitcity = split_part(owneraddress, ',', 2)

update nashville_housing 
set ownersplitstate = split_part(owneraddress, ',', 3)

select ownersplitaddress, ownersplitcity, ownersplitstate 
from nashville_housing nh;


-- Correct Y and N fields to Yes and No in 'Sold as Vacant' field

select distinct(soldasvacant), count(soldasvacant) 
from nashville_housing nh 
group by soldasvacant 

select soldasvacant,
case 
	when soldasvacant = 'Y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	else soldasvacant 
end
from nashville_housing nh 

update nashville_housing 
set soldasvacant = 
	case 
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant 
	end
where soldasvacant like 'Y' or soldasvacant like 'N';


-- Remove duplicates


with rownumCTE as (
select *, 
	row_number() over (
	partition by parcelid,
	propertyaddress,
	saledate,
	saleprice,
	legalreference
	order by "UniqueID"
	) row_num
from nashville_housing nh 
--order by parcelid 
)
select * 
from rownumCTE
where row_num > 1;
--order by propertyaddress 

delete
from nashville_housing nh 
WHERE (parcelid, propertyaddress, saledate, saleprice, legalreference, "UniqueID") IN (
  SELECT parcelid, propertyaddress, saledate, saleprice, legalreference, "UniqueID"
  FROM (
    SELECT parcelid, propertyaddress, saledate, saleprice, legalreference, "UniqueID", 
      ROW_NUMBER() OVER (PARTITION BY parcelid, propertyaddress, saledate, saleprice, legalreference ORDER BY "UniqueID") AS row_num
    FROM nashville_housing
  ) AS rownumCTE
  WHERE row_num > 1
);


-- Delete unused columns if needed

select *
from nashville_housing nh 

-- alter table nashville_housing
-- drop owneraddress, taxdistrict, propertyaddress, saledate





