library(rgeos)
library(rgdal)
library(raster)
library(maptools)
library(XML)


## make directory
dir.create("D:/GIS_DataBase/DEM/")
setwd("D:/GIS_DataBase/DEM/")
 
## get elevation data
filename <- "N47E011"
kml_file <- paste0("SLOPE_", filename, ".kml")
zip_file <- paste0(filename, ".zip")
url <- paste0("http://www.viewfinderpanoramas.org/dem1/", zip_file)
download.file(url, zip_file)
unzip(zip_file)
unlink(zip_file)

## read elevation data
x <- readGDAL(paste0("D:/Gis_Database/DEM/", filename, ".hgt"))

## coerce into RasterLayer object as desired by terrain function
y <- raster(x)

## calculate terrain
slo <- terrain(y, opt = "slope", unit = "degrees", df = F)

## check
# summary(values(slo))

## set values below 25 to NA, these will be transparent
## classes ->                                         1           2           3           4           5           6                                                                         
slo_final <- reclassify(slo, c(-Inf, 25, NA, 25, 30, 25, 30, 35, 30, 35, 40, 35, 40, 45, 40, 45, 50, 45, 50, 90, 50))

## inspect data
# hist(slo_final, breaks = 6)
# table(values(slo_final))

## set colors for slope angle classes and save as kml
colv <- rev(heat.colors(6))
KML(slo_final, file=kml_file, maxpixel = ncell(slo_final), 
    overwrite = T, blur = 2, col = colv)

## add transparency to kml
## the namespace issue (kml:) is explained in the getNodeSet(XML) R documentation under Details
doc <- xmlInternalTreeParse(kml_file)
over_node <- getNodeSet(doc, "/kml:kml/kml:GroundOverlay", c(kml = "http://www.opengis.net/kml/2.2"))
color_node <- newXMLNode("color", attr="6bffffff")
over_node[[1]] <- addChildren(over_node[[1]], color_node)

## save kml back & zip to kmz
## you will need to put in a suitable zipping program (i don't have 7-zip on the PATH, so
## I need to use an explicit system call..
saveXML(doc, kml_file)
cmd <- paste0('"C:\\Program Files\\7-Zip\\7z.exe"', ' a -tzip SLOPE_', filename, '.kmz ', kml_file, ' SLOPE_', filename, '.png')
cat(cmd)
system(cmd)
# shell.exec(paste0("SLOPE_", filename, ".kmz"))

## i externally uploaded the below legend to my server 
## for latter use in  adgoogle earth
png(file = "Legend.png", bg = "white")
plot.new()
title(main=list("Slope-Classes in Degrees:", cex=2.7))
legend("center", c("25-30", "30-35", "35-40", "40-45", "45-50", "50+"),
       pch = 15, cex = 3, col = colv, bty = "n")
dev.off()

cord <- t(matrix(bbox(slo_final)[,1]))
placement_legend <- SpatialPointsDataFrame(cord, data.frame(NA))
icon <- NULL
description <- "<img src='http://gimoya.bplaced.net/Terrain-Overlays/Legend.png'></img>"
kmlPoints(placement_legend, kmlfile="Legend.kml", kmlname="Slope-Legend", name="Click 'Slope-Legend' link for legend..", 
          description="", icon=icon, kmldescription=description)

# shell.exec("Legend.kml")