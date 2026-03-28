import sys
import json
from collections import defaultdict
from collections import OrderedDict

def get_json_paths(input_file):
    # Calls unpack which recursively calls itself.  The result is a comprehensive list of JSON paths
    # That we can use to access atomic data values.

    f = open(input_file)
    json_data = f.read()
    f.close()

    j = json.loads(json_data)
    paths = defaultdict(int)

    #Get all of the JSON paths other than the 'offset_X' that we inject in with ehapi.py
    for k in j.keys():
        #k will be 'offset_X', etc.  So j[k] is the actual value we're interested in
        v = j[k]

        unpack(pre_path="$.", test_obj=v, result_set=paths)

    # sort our dict
    paths = OrderedDict(sorted(paths.items()))  # Alphabetize

    # output paths and counts
    for key in paths.keys():
        print(key + '\t' + str(paths[key]))


def unpack(pre_path, test_obj, result_set):
    # Jason wrote this code back in 2015.  I've refactored some variable names here to reduce brain-melt
    # The function is recursive.  It calls itself until the test_obj is an atomic value

    if type(test_obj) is dict:
        for k in test_obj.keys():
            json_path = str(pre_path) + '.' + str(k)
            if type(test_obj[k]) is not list and type(test_obj[k]) is not dict:
                #print json_path
                result_set[json_path] += 1

            unpack(json_path, test_obj[k], result_set)

    elif type(test_obj) is list:
        for k in range(len(test_obj)):
            json_path = str(pre_path) + '.'
            if type(test_obj[k]) is not list and type(test_obj[k]) is not dict:
                #print json_path
                result_set[json_path] += 1

            unpack(json_path, test_obj[k], result_set)
    else:
        return

if __name__ == '__main__':
    get_json_paths(sys.argv[1])
