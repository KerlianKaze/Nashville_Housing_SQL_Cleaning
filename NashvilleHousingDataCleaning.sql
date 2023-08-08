/*

Cleaning Nashville Housing data in SQL

*/

--Data imported through the import wizard. Verify data looks correct from the source.

SELECT *
FROM PortfolioProject..NashvilleHousing

-- Standardize Date Format. Currently date/time format. Only need date.

SELECT SaleDate, CONVERT(date, SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted date;

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing

/*
 Populate missing Property Address Data. Looking at the data, ParcelID is tied to PropertyAddress.
 Use a self join on ParcelID where UniqueID is different. Use ISNULL to SET PropertyAddress.
 Use first query to verify NULL data. Use second query to SET the data. Use first query to verify second query worked.
*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

/*
Breaking out PropertyAddress into Individual Columns (Address, City, State).
Confirmed PropertyAddress only has commas and no other special characters.
Add new columns and use SUBSTRING to populate.
*/

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)
, ADD PropertySplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
, SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Verify data
SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing

/*
Breaking out OwnerAddress into Individual Columns (Address, City, State).
Use PARSENAME and REPLACE (replace ',' with '.') to populate.
*/

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT
  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnserSplitAddress
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)
, OwnerSplitCity Nvarchar(255)
, OwnerSplitState Nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--Verify Data
SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing

/*
Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant
*/

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

--Verify Data
SELECT DISTINCT SoldAsVacant
FROM PortfolioProject..NashvilleHousing

/*
Remove Duplicates
*/

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

/*
Delete Unused Columns
*/

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--Verify data
SELECT *
FROM PortfolioProject..NashvilleHousing
