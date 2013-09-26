#!/usr/local/bin/python

import sys
import argparse
from pyquery import PyQuery as pq
import re

__author__ = 'Sondov Engen'
 
parser = argparse.ArgumentParser(description='Extract index country constituency from msci.com')
parser.add_argument('-c','--category', help='Sets the category',required=False)
parser.add_argument('-lc','--list-categories', 
        help='lists all availabel index categories',
        action='store_true',
        required=False)
parser.add_argument('-li','--list-indices', 
        help='lists the available indices in a category',
        action='store_true',
        required=False)
parser.add_argument('query', metavar='query',
        nargs='*',
        help='the search string to match'
        )

args = parser.parse_args()
  
baseURL = "http://www.msci.com"

reqURL = baseURL + "/products/indices/tools/index_country_membership/"

d = pq(reqURL)


# Get categories
def to_cat(d):
    return {
            'name' : pq(d).text(), 
            'url': pq(d).find('a').attr('href'),
            'shortname' : (''.join([x[0] for x in pq(d).text().split()])).lower()
          }

categories = d('#navLevel3 > li').map(lambda i, d: to_cat(d))

curCat = d('#navLevel3 > li.selected').text()

def list_categories():
    print "Categories:"
    for c in categories:
        print " %s (%s)" % (c['name'], c['shortname'])

def getIndicies(d):
    return d('#selectedIndex > option').map(lambda i,d: {'name' : d.text, 'id' : pq(d).val()})

def list_indices(ixs):
    print "Indices (%s):" % (curCat,)
    for x in ixs:
        xid = x['id']
        try:
            xid = int(float(x['id']))
        except:
            pass
        print " %s (%s)" % (x['name'], xid)

if args.list_categories:
    list_categories()
    sys.exit(0)

if args.category:
    try:
        ncat = [x['name'] for x in categories if x['shortname'] == args.category][0]

        reqURL = baseURL + [x['url'] for x in categories if x['shortname'] == args.category][0]

        # update working selector if new category picked 
        if ncat != curCat:
            d = pq(reqURL)
            curCat = ncat

    except:
        print "Please supply a category shortname in the list of categories\n"
        list_categories()
        sys.exit(0)

ixs = getIndicies(d)

if args.list_indices:
    list_indices(ixs)
    sys.exit(0)


if not args.query:
    print "No instructions given, use -h for help"
    sys.exit(0)

# regex match against indices and and print results
# if unique match print country constituents

q = ' '.join(args.query)

qp = re.compile('.*' + q + '.*', flags=re.IGNORECASE)

matched = []

for x in ixs:
    if qp.match(x['name'] + " " + x['id']):
        matched.append(x)

if len(matched) > 1:
    list_indices(matched)
    sys.exit(0)

if len(matched) == 0:
    print 'No match found for index "%s" in category %s' % (q, curCat)
    print "HINT: try again with a differnt category. Use -lc to list categories"
    sys.exit(0)

if len(matched) == 1:
    idx = matched[0]

    sel = 'c'+idx['id']

    # hack to work around use of punctuations in 
    col = filter(lambda d: pq(d).attr('id') == sel, d('div'))

    if len(col) != 1:
        print "ERROR: more than one table matched id"
        sys.exit(-1) # change to correct error value

    s = pq(col[0])
    col = s.find('td.result').map(lambda i, d: d.text)

    print "Country constituents for %s:" % (idx['name'])

    for c in col:
        print c

