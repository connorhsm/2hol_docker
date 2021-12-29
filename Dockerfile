# Setup compile environment
FROM gcc:9.4.0 AS server_compiler
RUN apt update
RUN apt -y install libgl-dev libglu1-mesa-dev libsdl1.2-dev

# Copy in 2hol source code and then build the server
WORKDIR /src
COPY ./2hol ./
WORKDIR OneLife/server
RUN ./configure 1 && make

# Cleanup / remove unwanted files
RUN rm *.cpp *.h *.o *.dep2
RUN rm configure Makefile* makeFileList
RUN rm -r installYourOwnServer runServer.bat

# Move in required files
RUN mv /src/OneLifeData7/dataVersionNumber.txt .
RUN mv /src/OneLifeData7/objects .
RUN mv /src/OneLifeData7/categories .
RUN mv /src/OneLifeData7/transitions .
RUN mv /src/OneLifeData7/tutorialMaps .

# Move server into lean runtime environment
FROM debian:stable-slim

WORKDIR /server
COPY --from=server_compiler /src/OneLife/server ./

# Create symlinks for databases
WORKDIR /server_data/data
RUN ln -srt /server curseCount.db curses.db playerStats.db lookTime.db eve.db biome.db map.db floor.db mapTime.db grave.db floorTime.db meta.db
RUN ln -srt /server biomeRandSeed.txt curseSave.txt eveRadius.txt familyDataLog.txt mapDummyRecall.txt recentPlacements.txt

# Create symlinks for cache
WORKDIR /server_data/cache
RUN ln -sr ./categories_cache.fcz  /server/categories/cache.fcz
RUN ln -sr ./objects_cache.fcz     /server/objects/cache.fcz
RUN ln -sr ./transitions_cache.fcz /server/transitions/cache.fcz

WORKDIR /server_data/log
RUN ln -srt /server log.txt curseLog failureLog foodLog lifeLog mapChangeLogs

WORKDIR /server
COPY ./docker_entrypoint.sh ./
ENTRYPOINT ["./docker_entrypoint.sh"]

EXPOSE 8005
STOPSIGNAL SIGTSTP
CMD ["./OneLifeServer"]
