import os
from subprocess import Popen, PIPE
import shutil
import sys

build_dir = "build"

def read_bench():
    bench_name = sys.argv[1]
    return bench_name

def check_files(bench_name):
    if not os.path.isfile(bench_name):
        # TODO : Report error
        exit(1)

def replace_in_file(file, old, new):
    shutil.move(file, "temp")
    with open("temp", "rt") as fin:
        with open(file, "wt") as fout:
            for line in fin:
                fout.write(line.replace(old, new))
    os.remove("temp")

def make_tb(bench_name):
    replace_in_file("build/p2_tb.sv", "BENCH", bench_name)
    replace_in_file("build/params.sv", "BENCH", bench_name)

def run_bench(bench_name):
    process = Popen(['make', 'BENCH=' + bench_name], stdout=PIPE, stderr=PIPE)
    stdout, stderr = process.communicate()
    
    print("STANDARD ERROR:")
    print(str(stderr))
    print("STANDARD OUTPUT:")
    print(str(stdout))

def create_build():
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
    os.mkdir(build_dir)
    process = Popen("cp src/* build", shell=True)
    process.wait()

def fetch_bench(bench_name):
    process = Popen(['cp', 'benchmarks/' + bench_name + '.x', build_dir])
    process.wait()

bname = read_bench()
create_build()
fetch_bench(bname)

make_tb(bname)

os.chdir(build_dir)

run_bench(bname)
