-- Update photos for left and right microcabins
UPDATE accommodations 
SET image_url = 'https://github.com/milesan/test/blob/main/Copy%20of%20DSC07473.jpg?raw=trueg'
WHERE title IN ('Microcabin Left', 'Microcabin Right');