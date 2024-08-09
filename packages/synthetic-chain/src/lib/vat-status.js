/**
 * @file look up vat details from kernel DB
 * @see {makeSwingstore}
 */
// @ts-check
import process from 'node:process';
import dbOpenAmbient from 'better-sqlite3';
import { NonNullish } from './assert.js';

/** @import { Database, RegistrationOptions } from 'better-sqlite3'; */

export const swingstorePath = '~/.agoric/data/agoric/swingstore.sqlite';

/**
 * SQL short-hand
 *
 * @param {import('better-sqlite3').Database} db
 */
export const dbTool = db => {
  /**
   * @param {TemplateStringsArray} strings
   * @param  {...any} params
   */
  const prepare = (strings, ...params) => {
    const dml = strings.join('?');
    return { stmt: db.prepare(dml), params };
  };
  /**
   * @param {TemplateStringsArray} strings
   * @param  {...any} args
   */
  const sql = (strings, ...args) => {
    const { stmt, params } = prepare(strings, ...args);
    return stmt.all(...params);
  };
  /**
   * @param {TemplateStringsArray} strings
   * @param  {...any} args
   * @returns {any}
   */
  sql.get = (strings, ...args) => {
    const { stmt, params } = prepare(strings, ...args);
    return stmt.get(...params);
  };
  return sql;
};

/**
 * XXX misnomer; this isn't a general purpose swingStore; it's about vat details.
 *
 * @param {import('better-sqlite3').Database} db
 */
export const makeSwingstore = db => {
  const sql = dbTool(db);

  /** @param {string} key */
  const kvGet = key => sql.get`select * from kvStore where key = ${key}`.value;
  /** @param {string} key */
  const kvGetJSON = key => JSON.parse(kvGet(key));

  /** @param {string} vatID */
  const lookupVat = vatID => {
    return Object.freeze({
      source: () => kvGetJSON(`${vatID}.source`),
      options: () => kvGetJSON(`${vatID}.options`),
      currentSpan: () =>
        sql.get`select * from transcriptSpans where isCurrent = 1 and vatID = ${vatID}`,
    });
  };

  return Object.freeze({
    /** @param {string} vatName */
    findVat: vatName => {
      /** @type {string[]} */
      const dynamicIDs = kvGetJSON('vat.dynamicIDs');
      const targetVat = dynamicIDs.find(vatID =>
        lookupVat(vatID).options().name.includes(vatName),
      );
      if (!targetVat) throw Error(`vat not found: ${vatName}`);
      return targetVat;
    },
    /** @param {string} vatName */
    findVats: vatName => {
      /** @type {string[]} */
      const dynamicIDs = kvGetJSON('vat.dynamicIDs');
      return dynamicIDs.filter(vatID =>
        lookupVat(vatID).options().name.includes(vatName),
      );
    },
    lookupVat,
  });
};

/**
 * @param {{
 *   env?: { [name: string]: string | undefined };
 *   HOME?: string;
 * }} [io]
 */
export const locateSwingstore = (io = {}) => {
  const { env = process.env, HOME = env.HOME } = io;
  return swingstorePath.replace(/^~/, NonNullish(HOME));
};

/**
 * @param {import('./types.js').SwingStoreIO} [io]
 */
export const openSwingstore = (io = {}) => {
  const {
    fullPath = locateSwingstore(io),
    dbOpen = dbOpenAmbient,
    db = dbOpen(fullPath, { readonly: true }),
  } = io;
  return makeSwingstore(db);
};

/**
 * @param {string} vatName
 * @param {ReturnType<typeof makeSwingstore>} [kStore]
 */
export const getVatDetails = async (vatName, kStore = openSwingstore()) => {
  const vatID = kStore.findVat(vatName);
  const vatInfo = kStore.lookupVat(vatID);

  const source = vatInfo.source();
  const { incarnation } = vatInfo.currentSpan();
  return { vatName, vatID, incarnation, ...source };
};

/**
 * @param {string} vatName
 * @param {ReturnType<typeof makeSwingstore>} [kStore]
 */
export const getIncarnation = async (vatName, kStore = openSwingstore()) => {
  const details = await getVatDetails(vatName, kStore);

  // misc info to stderr
  console.error(JSON.stringify(details));

  return details.incarnation;
};
