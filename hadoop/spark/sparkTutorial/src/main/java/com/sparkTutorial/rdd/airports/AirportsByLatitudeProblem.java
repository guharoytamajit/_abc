package com.sparkTutorial.rdd.airports;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;

public class AirportsByLatitudeProblem {

    public static void main(String[] args) throws Exception {

        /* Create a Spark program to read the airport data from in/airports.text,  find all the airports whose latitude are bigger than 40.
           Then output the airport's name and the airport's latitude to out/airports_by_latitude.text.

           Each row of the input file contains the following columns:
           Airport ID, Name of airport, Main city served by airport, Country where airport is located, IATA/FAA code,
           ICAO Code, Latitude, Longitude, Altitude, Timezone, DST, Timezone in Olson format

           Sample output:
           "St Anthony", 51.391944
           "Tofino", 49.082222
           ...
         */
        SparkConf conf = new SparkConf().setAppName("hello").setMaster("local[2]");
        JavaSparkContext context = new JavaSparkContext(conf);
        JavaRDD<String> rows = context.textFile("in/airports.text");

        for (String str:rows.collect()
             ) {
            System.out.println(str);
        }
    }
}
