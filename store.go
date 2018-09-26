// Copyright 2017 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"bytes"
	"context"
	"encoding/gob"
	"os"
	"sync"

	"cloud.google.com/go/datastore"
	"github.com/boltdb/bolt"
)

type store interface {
	PutSnippet(ctx context.Context, id string, snip *snippet) error
	GetSnippet(ctx context.Context, id string, snip *snippet) error
}

type cloudDatastore struct {
	client *datastore.Client
}

func (s cloudDatastore) PutSnippet(ctx context.Context, id string, snip *snippet) error {
	key := datastore.NameKey("Snippet", id, nil)
	_, err := s.client.Put(ctx, key, snip)
	return err
}

func (s cloudDatastore) GetSnippet(ctx context.Context, id string, snip *snippet) error {
	key := datastore.NameKey("Snippet", id, nil)
	return s.client.Get(ctx, key, snip)
}

// inMemStore is a store backed by a map that should only be used for testing.
type inMemStore struct {
	sync.RWMutex
	m map[string]*snippet // key -> snippet
}

func (s *inMemStore) PutSnippet(_ context.Context, id string, snip *snippet) error {
	s.Lock()
	if s.m == nil {
		s.m = map[string]*snippet{}
	}
	b := make([]byte, len(snip.Body))
	copy(b, snip.Body)
	s.m[id] = &snippet{Body: b}
	s.Unlock()
	return nil
}

func (s *inMemStore) GetSnippet(_ context.Context, id string, snip *snippet) error {
	s.RLock()
	defer s.RUnlock()
	v, ok := s.m[id]
	if !ok {
		return datastore.ErrNoSuchEntity
	}
	*snip = *v
	return nil
}

func newLocalStore() (*localStore, error) {
	db, err := bolt.Open("/var/data/data.db", 0600, nil)
	if err != nil {
		os.MkdirAll("/var/data/", 0600)
		db, err = bolt.Open("/var/data/data.db", 0600, nil)
		if err != nil {
			return nil, err
		}
	}
	bucketName := "share"
	err = db.Update(func(tx *bolt.Tx) error { _, err := tx.CreateBucketIfNotExists([]byte(bucketName)); return err })
	if err != nil {
		return nil, err
	}

	return &localStore{db: db, bucketName: bucketName}, nil
}

// inMemStore is a store backed by a map that should only be used for testing.
type localStore struct {
	bucketName string
	db         *bolt.DB
}

func (l *localStore) PutSnippet(_ context.Context, id string, snip *snippet) error {
	return l.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(l.bucketName))
		buf := bytes.Buffer{}
		if err := gob.NewEncoder(&buf).Encode(snip); err != nil {
			return err
		}
		return b.Put([]byte(id), buf.Bytes())
	})
}

func (l *localStore) GetSnippet(_ context.Context, id string, snip *snippet) error {
	return l.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(l.bucketName))
		v := b.Get([]byte(id))
		return gob.NewDecoder(bytes.NewReader(v)).Decode(snip)
	})
}
