#!/usr/bin/env bash

# Note that this is only tested on macOS and may need adustments for other systems.

pushd() {
    command pushd "$@" > /dev/null
}

popd() {
    command popd "$@" > /dev/null
}

gnutime() {
    if hash gtime 2>/dev/null; then
        gtime "$@"
    else
        /usr/bin/time "$@"
    fi
}

print_average() {
    local array=("$@")
    local sum=0
    local count=${#array[@]}
    for i in "${array[@]}"; do
        sum=$(echo "$sum + $i" | bc)
    done
    echo "scale=2; $sum / $count" | bc -l
}

# Build all projects first so all assets (esp. static) on written to the file system. This seems to demonstrable affect the performance of the benchmarks.

echo "Performing initial clean and build for all projects..."

pushd simple

pushd mvc-dotnet-8
dotnet clean -v q && dotnet build -v q
popd

pushd mvc-dotnet-9
dotnet clean -v q && dotnet build -v q
popd

popd

pushd advanced

pushd mvc-dotnet-8
dotnet clean -v q && dotnet build -v q
popd

pushd mvc-dotnet-9
dotnet clean -v q && dotnet build -v q
popd

popd

# Run benchmarks

echo "Running benchmarks..."

simple_dotnet8_times=()
simple_dotnet9_times=()
advanced_dotnet8_times=()
advanced_dotnet9_times=()
build_command="dotnet build -v q"

pushd simple
pushd mvc-dotnet-8

for i in {1..5}; do
    saved_timing=`mktemp`
    gnutime --format="%e" -o "$saved_timing" $build_command
    dotnet_time=$(cat "$saved_timing")
    simple_dotnet8_times+=($dotnet_time)
done

popd
pushd mvc-dotnet-9

for i in {1..5}; do
    saved_timing=`mktemp`
    gnutime --format="%e" -o "$saved_timing" $build_command
    dotnet_time=$(cat "$saved_timing")
    simple_dotnet9_times+=($dotnet_time)
done

popd
popd

pushd advanced
pushd mvc-dotnet-8

for i in {1..5}; do
    saved_timing=`mktemp`
    gnutime --format="%e" -o "$saved_timing" $build_command
    dotnet_time=$(cat "$saved_timing")
    advanced_dotnet8_times+=($dotnet_time)
done

popd
pushd mvc-dotnet-9

for i in {1..5}; do
    saved_timing=`mktemp`
    gnutime --format="%e" -o "$saved_timing" $build_command
    dotnet_time=$(cat "$saved_timing")
    advanced_dotnet9_times+=($dotnet_time)
done

popd
popd

# Output results

bold=$(tput bold)
normal=$(tput sgr0)

echo "Benchmark results:"
echo -ne "${normal}Simple MVC .NET 8 (avg. seconds):\t${bold}"
print_average "${simple_dotnet8_times[@]}"
echo -ne "${normal}Simple MVC .NET 9 (avg. seconds):\t${bold}"
print_average "${simple_dotnet9_times[@]}"
echo -ne "${normal}Advanced MVC .NET 8 (avg. seconds):\t${bold}"
print_average "${advanced_dotnet8_times[@]}"
echo -ne "${normal}Advanced MVC .NET 9 (avg. seconds):\t${bold}"
print_average "${advanced_dotnet9_times[@]}"
