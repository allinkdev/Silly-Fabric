# Collect prebuilt binaries
FROM silly-build-collector as c2me-collector

RUN aria2c -s 16 -x 16 https://ci.codemc.io/job/RelativityMC/job/C2ME-fabric/job/ver%252F1.19.4/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o c2me.zip
RUN unzip c2me.zip -d c2me/

FROM silly-build-collector as vmp-collector

RUN aria2c -s 16 -x 16 https://ci.codemc.io/job/RelativityMC/job/VMP-fabric/job/ver%252F1.19.4/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o vmp.zip
RUN unzip vmp.zip -d vmp/

FROM silly-build-collector as raknetify-collector

RUN aria2c -s 16 -x 16 https://ci.codemc.io/job/RelativityMC/job/raknetify/job/master/lastSuccessfulBuild/artifact/fabric/build/libs/*zip*/libs.zip -o raknetify.zip
RUN unzip raknetify.zip -d raknetify/

FROM silly-build-collector as viaversion-collector

#RUN aria2c -s 16 -x 16 https://ci.viaversion.com/job/ViaVersion-DEV/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o viaversion.zip
RUN aria2c -s 16 -x 16 https://ci.viaversion.com/job/ViaVersion/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o viaversion.zip
RUN unzip viaversion.zip -d viaversion/

FROM silly-build-collector as viabackwards-collector
USER builder

#RUN aria2c -s 16 -x 16 https://ci.viaversion.com/view/ViaBackwards/job/ViaBackwards-DEV/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o viabackwards.zip
RUN aria2c -s 16 -x 16 https://ci.viaversion.com/view/ViaBackwards/job/ViaBackwards/lastSuccessfulBuild/artifact/build/libs/*zip*/libs.zip -o viabackwards.zip
RUN unzip viabackwards.zip -d viabackwards/

FROM silly-build-collector as viarewind-collector

RUN aria2c -s 16 -x 16 https://ci.viaversion.com/view/ViaRewind/job/ViaRewind/lastSuccessfulBuild/artifact/all/target/*zip*/target.zip -o viarewind.zip
RUN unzip viarewind.zip -d viarewind/

FROM silly-build-collector as viafabric-collector

RUN aria2c -s 16 -x 16 https://nightly.link/ViaVersion/ViaFabric/workflows/build/main/Artifacts.zip -o viafabric.zip
RUN unzip viafabric.zip -d viafabric/

FROM silly-build-collector as fabric-server-collector

RUN aria2c -s 16 -x 16 https://meta.fabricmc.net/v2/versions/loader/1.19.4/0.14.17/0.11.2/server/jar -o server.jar

FROM silly-gradle-builder as krypton-builder

RUN git clone https://github.com/astei/krypton.git --depth=1 "krypton"

WORKDIR /build/krypton
RUN ./gradlew --no-daemon build --stacktrace --info
RUN rm build/libs/*-sources.jar

FROM silly-gradle-builder as lithium-builder

RUN git clone https://github.com/CaffeineMC/lithium-fabric.git -b "develop" --depth=1 "lithium-fabric"

WORKDIR /build/lithium-fabric
RUN ./gradlew --no-daemon build --stacktrace --info

FROM silly-gradle-builder as ferritecore-builder

RUN git clone https://github.com/malte0811/FerriteCore.git -b "1.19" --depth=1 "FerriteCore"

WORKDIR /build/FerriteCore
RUN ./gradlew --no-daemon Fabric:build --stacktrace --info

FROM silly-gradle-builder as alternate-current-builder

RUN git clone https://github.com/SpaceWalkerRS/alternate-current.git -b "main" --depth=1 "alternate-current"

WORKDIR /build/alternate-current
RUN ./gradlew --no-daemon build --stacktrace --info
RUN rm build/libs/*-sources.jar

FROM silly-gradle-builder as starlight-builder

RUN git clone https://github.com/PaperMC/Starlight.git -b "fabric" --depth=1 "Starlight"

WORKDIR /build/Starlight
RUN ./gradlew --no-daemon build --stacktrace --info
RUN rm build/libs/*-sources.jar

FROM eclipse-temurin:17-jdk-alpine as server-launcher

COPY --from=fabric-server-collector /collect/server.jar server.jar
RUN java -Xmx2g -jar server.jar

#FROM silly-gradle-builder as fastload-builder

# TODO: Uncomment and change branch when updated to 1.19.4
#RUN git clone https://github.com/BumbleSoftware/Fastload.git -b "Fabric-1.19.3" --depth=1 "Fastload"

#WORKDIR /build/Fastload
#RUN chmod a+x gradlew
#RUN ./gradlew --no-daemon build --stacktrace --info
#RUN rm build/libs/*-sources.jar

FROM alpine as server-creator
RUN addgroup -g 65532 -S nonroot
RUN adduser -G nonroot -h /server/ -S -D -u 65532 nonroot
USER nonroot:nonroot

WORKDIR /server/
RUN echo "eula=true" >> eula.txt
RUN mkdir mods

WORKDIR /server/mods/

# Relativity MC
COPY --from=c2me-collector --chown=nonroot:nonroot /collect/c2me/libs/*.jar C2ME.jar
COPY --from=vmp-collector --chown=nonroot:nonroot /collect/vmp/libs/*.jar VMP.jar
COPY --from=raknetify-collector --chown=nonroot:nonroot /collect/raknetify/libs/*.jar Raknetify.jar

# ViaVersion
COPY --from=viaversion-collector --chown=nonroot:nonroot /collect/viaversion/libs/*.jar ViaVersion.jar
COPY --from=viabackwards-collector --chown=nonroot:nonroot /collect/viabackwards/libs/*.jar ViaBackwards.jar
COPY --from=viarewind-collector --chown=nonroot:nonroot /collect/viarewind/target/*.jar ViaRewind.jar
COPY --from=viafabric-collector --chown=nonroot:nonroot /collect/viafabric/*-main.jar ViaFabric.jar

# Astei
COPY --from=krypton-builder --chown=nonroot:nonroot /build/krypton/build/libs/*.jar Krypton.jar

# Caffeine MC
COPY --from=lithium-builder --chown=nonroot:nonroot /build/lithium-fabric/build/libs/*-SNAPSHOT.jar Lithium.jar

# malte0811
COPY --from=ferritecore-builder --chown=nonroot:nonroot /build/FerriteCore/Fabric/build/libs/*.jar FerriteCore.jar

# SpaceWalkerRS
COPY --from=alternate-current-builder --chown=nonroot:nonroot /build/alternate-current/build/libs/*.jar AlternateCurrent.jar

# PaperMC
COPY --from=starlight-builder --chown=nonroot:nonroot /build/Starlight/build/libs/*.jar Starlight.jar

# Bumble Software
# Read build TODO
# COPY --from=fastload-builder --chown=nonroot:nonroot /build/Fastload/build/libs/*.jar Fastload.jar

# User-defined
ADD --chown=nonroot:nonroot mods/*.jar ./

WORKDIR /server/

ADD --chown=nonroot:nonroot server.properties ./

COPY --from=server-launcher --chown=nonroot:nonroot /libraries/ libraries/
COPY --from=server-launcher --chown=nonroot:nonroot /versions/ versions/
COPY --from=server-launcher --chown=nonroot:nonroot /.fabric/ .fabric/
COPY --from=fabric-server-collector --chown=nonroot:nonroot /collect/server.jar server.jar

FROM gcr.io/distroless/java17-debian11:nonroot

COPY --from=server-creator --chown=nonroot:nonroot /server/ /server/

USER nonroot:nonroot

WORKDIR /server/
ENTRYPOINT [ "java", "-Xmx2g", "-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled", "-XX:MaxGCPauseMillis=200", "-XX:+UnlockExperimentalVMOptions", "-XX:+DisableExplicitGC", "-XX:+AlwaysPreTouch", "-XX:G1NewSizePercent=30", "-XX:G1MaxNewSizePercent=40", "-XX:G1HeapRegionSize=8M", "-XX:G1ReservePercent=20", "-XX:G1HeapWastePercent=5", "-XX:G1MixedGCCountTarget=4", "-XX:InitiatingHeapOccupancyPercent=15", "-XX:G1MixedGCLiveThresholdPercent=90", "-XX:G1RSetUpdatingPauseTimePercent=5", "-XX:SurvivorRatio=32", "-XX:+PerfDisableSharedMem", "-XX:MaxTenuringThreshold=1", "-jar", "server.jar", "nogui" ]